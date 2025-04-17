<template>
    <v-dialog v-model="customIdDialog">
        <v-card>
            <v-card-title>
                <span class="text-subtile-1">Insert new Submodel Template</span>
            </v-card-title>
            <v-divider></v-divider>
            <v-expansion-panels v-model="openPanels" multiple>
                <v-expansion-panel class="border-thin">
                    <v-expansion-panel-title>Details</v-expansion-panel-title>
                    <v-expansion-panel-text>
                        <TextInput v-model="submodelId" label="ID" :show-generate-iri-button="true" type="Submodel" />
                    </v-expansion-panel-text>
                </v-expansion-panel>
            </v-expansion-panels>
            <v-divider></v-divider>
            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn @click="closeDialog">Cancel</v-btn>
                <v-btn color="primary" @click="createST">Next</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script setup lang="ts">
    import { ref, watch } from 'vue';
    import { useIDUtils } from '@/composables/IDUtils';

    const props = defineProps<{
        modelValue: boolean;
    }>();

    const emit = defineEmits<{
        (event: 'update:modelValue', value: boolean): void;
        (event: 'createST', id: string): void;
        (event: 'closeIdDialog'): void;
    }>();

    const { generateUUID } = useIDUtils();

    const customIdDialog = ref<boolean>(false);
    const submodelId = ref<string>(generateUUID());
    const openPanels = ref<number[]>([0]);

    watch(
        () => props.modelValue,
        (value) => {
            customIdDialog.value = value;
        }
    );

    function closeDialog(): void {
        emit('closeIdDialog');
    }

    function createST(): void {
        emit('createST', submodelId.value);
        closeDialog();
    }
</script>
