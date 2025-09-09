<template>
    <v-dialog v-model="showDialog" persistent max-width="500">
        <v-card>
            <v-card-title>
                <span>Add ID to RBAC Rule</span>
            </v-card-title>
            <v-divider></v-divider>
            <v-card-text>
                <span>Enter the ID you want to add to the RBAC Rule:</span>
                <v-text-field
                    v-model="id"
                    label="ID"
                    density="compact"
                    variant="outlined"
                    class="mt-2"
                    :error="error" />
            </v-card-text>
            <v-card-actions>
                <v-btn color="error" @click="close">Cancel</v-btn>
                <v-spacer></v-spacer>
                <v-btn color="primary" @click="checkAndAdd(id)">Add</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script setup lang="ts">
    import { onMounted, ref, watch } from 'vue';

    const id = ref('');
    const showDialog = ref(false);
    const error = ref(false);

    const props = defineProps({
        addId: {
            type: Function,
            required: true,
        },
        close: {
            type: Function,
            required: true,
        },
        modelValue: {
            type: Boolean,
            required: true,
        },
    });

    watch(
        () => props.modelValue,
        (newValue: boolean) => {
            showDialog.value = newValue;
            initialize();
        }
    );

    onMounted(() => {
        initialize();
    });

    function initialize() {
        id.value = '';
        error.value = false;
    }

    function checkAndAdd(idToAdd: string) {
        if (idToAdd && idToAdd.trim() !== '') {
            props.addId(idToAdd.trim());
            id.value = '';
            showDialog.value = false;
        } else {
            alert('ID cannot be empty');
            error.value = true;
        }
    }
</script>
