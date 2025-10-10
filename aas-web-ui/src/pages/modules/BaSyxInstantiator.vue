<template>
    <v-container class="pa-md-6" fluid>
        <v-navigation-drawer
            absolute
            class="ma-4"
            rounded="lg"
            border
            rail
            expand-on-hover
            style="height: calc(100vh - 134px)"
            persistent>
            <v-list
                active-class="border-thin border-primary border-opacity-25"
                bg-color="transparent"
                class="pt-2 ga-2 d-flex flex-column"
                color="primary"
                density="comfortable"
                slim>
                <v-list-item
                    v-for="(item, i) in getSteps"
                    :key="i"
                    border="thin surface"
                    rounded="lg"
                    :subtitle="item.subtitle"
                    :title="item.title"
                    :value="i"
                    class="mx-2"
                    style="cursor: default; user-select: none"
                    :disabled="item.disabled"
                    :active="model === i">
                    <template #prepend>
                        <v-icon class="ml-n2">{{ item.icon }}</v-icon>
                    </template>
                </v-list-item>
            </v-list>
        </v-navigation-drawer>
        <v-card border class="pa-4 mt-n2" flat rounded="lg" align="center">
            <div>
                <div class="text-h6 font-weight-bold">{{ settings[model].title }}</div>
                <div class="text-body-2 text-medium-emphasis">
                    {{ settings[model].subtitle }}
                </div>
            </div>
            <v-select
                v-model="selectedTemplate"
                variant="outlined"
                density="comfortable"
                label="Submodel Template"
                class="mt-4"
                clearable
                max-width="400"
                :items="templateIdShorts" />
            <template #actions>
                <v-spacer></v-spacer>
                <v-btn :disabled="selectedTemplate == null" color="success" variant="tonal">Start Creation</v-btn>
                <v-spacer></v-spacer>
            </template>
        </v-card>
    </v-container>
    <v-btn
        style="position: fixed; bottom: 64px; right: 16px; z-index: 999999999"
        icon="mdi-arrow-up"
        @click="scrollToTop"></v-btn>
</template>

<script lang="ts" setup>
    //----- Imports -----//
    import { ModellingKind, ModelType, type Submodel } from '@aas-core-works/aas-core3.0-typescript/types';
    import { Configuration, SubmodelRepositoryClient } from 'basyx-typescript-sdk';
    import { computed, onMounted, onUnmounted, ref, watch } from 'vue';

    //----- Component Options -----//
    defineOptions({
        inheritAttrs: false,
        isDesktopModule: true,
        isMobileModule: false,
    });

    //----- Types -----//
    interface Step {
        title: string;
        subtitle: string;
        icon: string;
        addBtn: boolean;
        disabled?: boolean;
    }

    //----- State -----//
    const model = ref(0);
    const templates = ref<Submodel[]>();
    const selectedTemplate = ref<string | null>(null);
    const settings = ref<Step[]>([
        {
            title: 'Choose a Submodel template',
            subtitle: 'Select the Template to be created',
            icon: 'mdi-cog-outline',
            addBtn: false,
            disabled: false,
        },
    ]);
    const submodelTemplateSpecificSteps = ref<Step[]>([]);
    const preloadedSMT = ref<Submodel | null>(null);

    //----- Watchers -----//
    watch(model, () => {
        scrollToTop();
    });

    watch(selectedTemplate, (newVal) => {
        if (newVal) {
            preloadedSMT.value = templates.value?.find((template) => template.id === newVal) ?? null;
            submodelTemplateSpecificSteps.value = getStepsForCurrentSubmodelTemplate();
        } else {
            preloadedSMT.value = null;
            submodelTemplateSpecificSteps.value = [];
        }
    });

    //----- Computed -----//
    const templateIdShorts = computed(() => {
        return templates.value?.map((template) => template.id) ?? [];
    });

    const getSteps = computed(() => {
        return settings.value.concat(submodelTemplateSpecificSteps.value);
    });

    //----- Lifecycle Hooks -----//
    onMounted(async () => {
        templates.value = await getIDTASubmodelTemplates();

        // Add beforeunload event listener for reload warning
        window.addEventListener('beforeunload', handleBeforeUnload);
    });

    onUnmounted(() => {
        // Clean up event listener
        window.removeEventListener('beforeunload', handleBeforeUnload);
    });

    //----- Methods -----//
    function getStepsForCurrentSubmodelTemplate(): Step[] {
        let steps: Step[] = [];
        let hasNonCollectionElements = false;

        preloadedSMT.value?.submodelElements?.forEach((submodelElement) => {
            if (submodelElement.modelType() !== ModelType.SubmodelElementCollection) {
                hasNonCollectionElements = true;
            }
        });

        if (hasNonCollectionElements) {
            steps.push({
                title: 'General Element Collection',
                subtitle: 'Holds all general Items',
                icon: 'mdi-debug-step-into',
                addBtn: false,
                disabled: true,
            });
        }

        preloadedSMT.value?.submodelElements?.forEach((submodelElement) => {
            const mandatory = submodelElement?.qualifiers?.some(
                (qualifier) =>
                    qualifier.type.includes('Cardinality') &&
                    (qualifier.value === 'One' || qualifier.value === 'OneToMany')
            );

            if (submodelElement.modelType() === ModelType.SubmodelElementCollection) {
                steps.push({
                    title: submodelElement.idShort || 'Unnamed Element',
                    subtitle: mandatory ? 'Mandatory Element' : 'Optional Element',
                    icon: 'mdi-debug-step-into',
                    addBtn: false,
                    disabled: true,
                });
            }
        });

        return steps;
    }

    function scrollToTop(): void {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    async function getIDTASubmodelTemplates(): Promise<Submodel[]> {
        const client = new SubmodelRepositoryClient();
        const configuration = new Configuration({
            basePath: 'https://smt-repo.admin-shell-io.com/api/v3.0',
        });
        try {
            const response = await client.getAllSubmodels({ configuration });

            if (response.success) {
                return response.data.result.filter((submodel) => submodel.kind === ModellingKind.Template);
            } else {
                console.error('Failed to fetch IDTA Templates:', response.error);
                return [];
            }
        } catch (error) {
            console.error('Error fetching IDTA Templates:', error);
            return [];
        }
    }

    function handleBeforeUnload(event: BeforeUnloadEvent): string | void {
        // Show warning if user has selected a template (indicating work in progress)
        if (selectedTemplate.value) {
            const message = 'Are you sure you want to reload? Your progress will be lost.';
            event.preventDefault();
            event.returnValue = message; // Required for Chrome
            return message; // Required for other browsers
        }
    }
</script>
