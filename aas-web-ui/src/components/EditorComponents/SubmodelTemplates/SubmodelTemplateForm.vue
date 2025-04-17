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
                <v-btn color="primary" :disabled="selectedST == ''" @click="openIdEditor">Next</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
    <ChangeIdForm v-model="customIdDialog" @close-id-dialog="closeIdEditor" @create-s-t="createST"></ChangeIdForm>
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
    import { smts } from '@/utils/AAS/SubmodelTemplateUtils';
    import { base64Encode } from '@/utils/EncodeDecodeUtils';
    import ChangeIdForm from './ChangeIdForm.vue';

    const client = useSMRepositoryClient();
    const aasStore = useAASStore();
    const router = useRouter();
    const { putAas } = useAASRepositoryClient();
    const navigationStore = useNavigationStore();
    const submodelTemplates: any[] = smts;
    const insertSTDialog = ref(false);
    const customIdDialog = ref(false);
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
        if (Object.prototype.hasOwnProperty.call(submodelTemplate, 'fileName'))
            availableST.value.push(`${submodelTemplate.name} ${submodelTemplate.version}`);
    });
    const selectedST = ref(`${submodelTemplates[1].name} ${submodelTemplates[1].version}`);
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

    async function createST(id: string): Promise<void> {
        if (selectedST.value == '') return;
        //load json file
        const metaData: any = submodelTemplates.find((mapping) => {
            return mapping.name + ' ' + mapping.version === selectedST.value;
        });
        if (!metaData) {
            console.error('Error while loading Submodel Template ' + selectedST.value);
            return;
        }
        const data = await fetch('/SubmodelTemplates/' + metaData.fileName);
        const json = await data.json();
        const submodel = json.submodels[0];
        submodel.id = id;
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

    function openIdEditor(): void {
        customIdDialog.value = true;
    }

    function closeIdEditor(): void {
        customIdDialog.value = false;
    }
</script>
