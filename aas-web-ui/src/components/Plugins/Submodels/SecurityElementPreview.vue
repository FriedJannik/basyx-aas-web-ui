<template>
    <v-container fluid class="pa-0">
        <v-card title="RBAC Rule Overview" prepend-icon="mdi-list-status">
            <v-divider></v-divider>
            <v-card-text>
                <v-alert class="mb-6" variant="tonal" border :color="isEditMode ? 'error' : 'primary'">
                    <span v-if="isEditMode">
                        You are currently editing the RBAC rule. Changes apply <strong>immediately.</strong>
                    </span>
                    <span v-else>
                        You are currently in view mode. To edit the RBAC rule, click the edit button in the top right
                    </span>
                </v-alert>
                <v-row>
                    <v-col>
                        <div>
                            <v-combobox
                                v-model="type.value"
                                :items="availableTypes"
                                label="Type"
                                variant="outlined"
                                density="compact"
                                disabled>
                            </v-combobox>
                        </div>
                        <div>
                            <v-combobox
                                v-model="action.value"
                                :items="availableActions"
                                label="Action"
                                variant="outlined"
                                density="compact"
                                :disabled="!isEditMode"
                                @update:model-value="updateAction">
                            </v-combobox>
                        </div>
                        <div>
                            <v-combobox
                                v-model="role.value"
                                :items="availableRoles"
                                label="Role"
                                variant="outlined"
                                density="compact"
                                :disabled="!isEditMode"
                                @update:model-value="updateRole">
                            </v-combobox>
                        </div>
                    </v-col>
                    <v-divider vertical class="my-n2"></v-divider>
                    <v-col>
                        <div v-for="tI in targetInformation" :key="tI.idShort">
                            <v-card :title="tI.idShort">
                                <v-divider></v-divider>
                                <v-card-text>
                                    <v-data-table-virtual
                                        :headers="idTableHeaders"
                                        :items="getIdList(tI)"
                                        density="compact"
                                        style="overflow-y: auto; max-height: 300px"
                                        fixed-header>
                                        <template #[`item.actions`]="{ item }">
                                            <v-btn
                                                :title="'Delete'"
                                                icon
                                                size="small"
                                                variant="text"
                                                color="primary"
                                                :disabled="!isEditMode"
                                                @click="deleteID(tI.idShort, item)">
                                                <v-icon>mdi-delete</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-data-table-virtual>
                                </v-card-text>
                                <v-card-actions>
                                    <v-spacer></v-spacer>
                                    <v-btn
                                        class="mr-2"
                                        variant="tonal"
                                        color="primary"
                                        :disabled="!isEditMode"
                                        @click="
                                            addIdDialog = true;
                                            selectedTargetInformation = tI;
                                        "
                                        >Add ID</v-btn
                                    >
                                </v-card-actions>
                            </v-card>
                        </div>
                    </v-col>
                </v-row>
            </v-card-text>
            <template #append>
                <v-tooltip :open-delay="500">
                    <template #activator="{ props: t_props }">
                        <v-btn
                            rounded
                            flat
                            variant="outlined"
                            color="primary"
                            v-bind="t_props"
                            @click="isEditMode = !isEditMode">
                            <v-icon>{{ isEditMode ? 'mdi-pen-off' : 'mdi-pen' }}</v-icon>
                        </v-btn>
                    </template>
                    <span>{{ isEditMode ? 'Stop Editing RBAC Rule' : 'Edit RBAC Rule' }}</span>
                </v-tooltip>
            </template>
        </v-card>
    </v-container>
    <IdDialog v-model="addIdDialog" :add-id="addIdToList" :close="closeIdDialog" />
</template>

<script lang="ts" setup>
    import { computed, ref } from 'vue';
    import { useRoute } from 'vue-router';
    import { useSMEHandling } from '@/composables/AAS/SMEHandling';
    import { useRequestHandling } from '@/composables/RequestHandling';
    import { useAuthStore } from '@/store/AuthStore';
    import { useNavigationStore } from '@/store/NavigationStore';

    defineOptions({
        name: 'DynamicRBACRule',
        semanticId: 'https://iese.fraunhofer.de/semanticId/DynamicRBACRule',
    });

    // Composables
    const { patchRequest, deleteRequest, postRequest } = useRequestHandling();
    const { fetchAndDispatchSme } = useSMEHandling();
    const route = useRoute();

    // Reactive state
    const isEditMode = ref<boolean>(false);
    const selectedTargetInformation = ref<any>(null);

    // Stores
    const authStore = useAuthStore();
    const navigationStore = useNavigationStore();

    const props = defineProps({
        submodelElementData: {
            type: Object,
            required: true,
        },
    });

    const role = computed(() => props.submodelElementData.value.find((el: any) => el.idShort === 'role') || 'N/A');
    const availableRoles = computed(() => authStore.getKeycloak?.realmAccess?.roles);
    const action = computed(
        () => props.submodelElementData.value.find((el: any) => el.idShort === 'action')?.value[0] || 'N/A'
    );
    const availableActions = ref(['CREATE', 'READ', 'UPDATE', 'DELETE']);
    const type = computed(
        () =>
            props.submodelElementData.value
                .find((el: any) => el.idShort === 'targetInformation')
                ?.value.find((info: any) => info.idShort === '@type') || 'N/A'
    );
    const targetInformation = computed(() =>
        props.submodelElementData.value
            .find((el: any) => el.idShort === 'targetInformation')
            ?.value.filter((info: any) => info.idShort !== '@type')
    );

    const availableTypes = ref([
        'aas-registry',
        'aas',
        'submodel',
        'submodel-registry',
        'aas-discovery-service',
        'aas-environment',
    ]);
    const idTableHeaders = ref<any[]>([
        { title: 'ID', key: 'ID' },
        { title: 'Actions', key: 'actions', align: 'end' },
    ]);
    const addIdDialog = ref(false);

    // Methods
    function updateRole(newRole: string): void {
        patchRequest(
            route.query.path + '.role/$value',
            JSON.stringify(newRole),
            new Headers({ 'Content-Type': 'application/json' }),
            'Updating RBAC Role',
            false
        );
    }

    function updateAction(newAction: string): void {
        patchRequest(
            route.query.path + '.action%5B0%5D/$value',
            JSON.stringify(newAction),
            new Headers({ 'Content-Type': 'application/json' }),
            'Updating RBAC Action',
            false
        );
    }

    function deleteID(targetInformationIdShort: string, id: any): void {
        deleteRequest(
            route.query.path + '.targetInformation.' + targetInformationIdShort + '%5B' + id.index + '%5D',
            'Deleting ID',
            false
        ).then(() => {
            navigationStore.dispatchTriggerTreeviewReload();
            fetchAndDispatchSme(route.query.path as string, true);
        });
    }
    function addIdToList(id: any): void {
        const payload = JSON.stringify({
            idShort: '',
            modelType: 'Property',
            value: id,
        });

        postRequest(
            route.query.path + '.targetInformation.' + selectedTargetInformation.value.idShort,
            payload,
            new Headers({ 'Content-Type': 'application/json' }),
            'Adding ID',
            false
        ).then(() => {
            closeIdDialog();
            navigationStore.dispatchTriggerTreeviewReload();
            fetchAndDispatchSme(route.query.path as string, true);
        });
    }

    function closeIdDialog(): void {
        addIdDialog.value = false;
    }

    function getIdList(targetInformation: any): any[] {
        const submodelElements = targetInformation.value;
        let returnValue: any[] = [];
        let index = 0;
        if (!submodelElements) return returnValue;
        for (const sme of submodelElements) {
            returnValue.push({ ID: sme.value, index: index++ });
        }
        return returnValue;
    }
</script>
