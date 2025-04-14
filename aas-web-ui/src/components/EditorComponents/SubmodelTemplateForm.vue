<template>
    <v-dialog v-model="insertSTDialog" width="860" persistent>
        <v-card>
            <v-card-title>
                <span class="text-subtile-1">Insert new Submodel Template</span>
            </v-card-title>
            <v-divider></v-divider>
            <v-select
                v-model="selectedST"
                class="px-4 pt-4"
                :items="availableST"
                label="Select Submodel Template"
                required
                variant="outlined"
                density="compact">
            </v-select>
            <v-divider></v-divider>
            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn @click="closeDialog">Cancel</v-btn>
                <v-btn color="primary" :disabled="selectedST == ''" @click="createST">Next</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script setup lang="ts">
    import { jsonization, types } from '@aas-core-works/aas-core3.0-typescript';
    import { computed, ref, watch } from 'vue';
    import { useRouter } from 'vue-router';
    import { useAASRepositoryClient } from '@/composables/Client/AASRepositoryClient';
    import { useSMRepositoryClient } from '@/composables/Client/SMRepositoryClient';
    import { useAASStore } from '@/store/AASDataStore';
    import { useNavigationStore } from '@/store/NavigationStore';
    import { extractEndpointHref } from '@/utils/AAS/DescriptorUtils';
    import { base64Encode } from '@/utils/EncodeDecodeUtils';
    import { getSubmodelTemplateMapping, SubmodelTemplateMetadata } from '@/utils/SubmodelTemplateUtils';

    const client = useSMRepositoryClient();
    const aasStore = useAASStore();
    const router = useRouter();
    const { putAas } = useAASRepositoryClient();
    const navigationStore = useNavigationStore();
    const submodelTemplates: SubmodelTemplateMetadata[] = getSubmodelTemplateMapping();
    const insertSTDialog = ref(false);
    const selectedAAS = computed(() => aasStore.getSelectedAAS); // Get the selected AAS from Store
    const submodelRepoUrl = computed(() => navigationStore.getSubmodelRepoURL);
    const props = defineProps<{
        modelValue: boolean;
    }>();
    const emit = defineEmits<{
        (event: 'update:modelValue', value: boolean): void;
    }>();
    const availableST = ref<string[]>([]);
    submodelTemplates.forEach((submodelTemplate) => {
        availableST.value.push(submodelTemplate.id);
    });
    const selectedST = ref('Digital Nameplate 3.0');
    watch(
        () => props.modelValue,
        (value) => {
            insertSTDialog.value = value;
        }
    );
    watch(
        () => insertSTDialog.value,
        (value) => {
            emit('update:modelValue', value);
        }
    );

    function closeDialog(): void {
        insertSTDialog.value = false;
    }

    async function createST(): Promise<void> {
        if (selectedST.value == '') return;
        //load json file
        const metaData: SubmodelTemplateMetadata | undefined = getSubmodelTemplateMapping().find((mapping) => {
            return mapping.id === selectedST.value;
        });
        if (!metaData) {
            console.error('Error while loading Submodel Template ' + selectedST.value);
            return;
        }
        const data = await fetch('/SubmodelTemplates/' + metaData.fileName);
        const json = await data.json();
        json.submodels.forEach(async (submodel: string) => {
            const instanceOrError = jsonization.submodelFromJsonable(submodel);
            if (instanceOrError.error != null) {
                console.error('Error while deserializing Submodel for Submodel Template ', selectedST.value);
                return;
            }
            const submodelObject = instanceOrError.mustValue();
            client.postSubmodel(submodelObject);
            // Add Submodel Reference to AAS
            await addSubmodelReferenceToAas(submodelObject);
            // Fetch and dispatch Submodel
            const path = submodelRepoUrl.value + '/' + base64Encode(submodelObject.id);
            const aasEndpoint = extractEndpointHref(selectedAAS.value, 'AAS-3.0');
            router.push({ query: { aas: aasEndpoint, path: path } });
            navigationStore.dispatchTriggerTreeviewReload();
        });
        closeDialog();
    }

    async function addSubmodelReferenceToAas(submodel: types.Submodel): Promise<void> {
        if (selectedAAS.value === null) return;
        const localAAS = { ...selectedAAS.value };
        const instanceOrError = jsonization.assetAdministrationShellFromJsonable(localAAS);
        if (instanceOrError.error !== null) {
            console.error('Error parsing AAS: ', instanceOrError.error);
            return;
        }
        const aas = instanceOrError.mustValue();
        // Create new SubmodelReference
        const submodelReference = new types.Reference(types.ReferenceTypes.ExternalReference, [
            new types.Key(types.KeyTypes.Submodel, submodel.id),
        ]);
        // Check if Submodels are null
        if (aas.submodels === null || aas.submodels === undefined) {
            aas.submodels = [submodelReference];
            localAAS.submodels = [jsonization.toJsonable(submodelReference)];
        } else {
            aas.submodels.push(submodelReference);
            localAAS.submodels.push(jsonization.toJsonable(submodelReference));
        }
        await putAas(aas);

        // Update AAS in Store
        aasStore.dispatchSelectedAAS(localAAS);
    }
</script>
