<template>
    <div v-if="sme instanceof SubmodelElementList || sme instanceof SubmodelElementCollection">
        <div v-for="subSme in sme.value" :key="subSme.idShort">
            <v-list-item-subtitle>{{ subSme.idShort }}</v-list-item-subtitle>
            <NestedInputFieldGenerator
                :is-mandatory="isMandatory"
                :sme="subSme"
                :level="level + 1"
                :class="`ml-${level + 1}`" />
        </div>
    </div>
    <div v-else>
        <v-text-field density="compact" variant="outlined" :label="sme.idShort + ' ' + (isMandatory(sme) ? '*' : '')">
            <template v-if="sme.description && sme.description[0].text" #append>
                <v-tooltip top>
                    <template #activator="{ props }">
                        <v-btn icon="mdi-information" elevation="0" size="small" v-bind="props"></v-btn>
                    </template>
                    <span>{{ sme.description[0].text }}</span>
                </v-tooltip>
            </template>
        </v-text-field>
    </div>
</template>

<script setup lang="ts">
    import { SubmodelElementCollection, SubmodelElementList } from '@aas-core-works/aas-core3.0-typescript/types';

    defineProps<{
        isMandatory: (submodelElement: any) => boolean;
        sme: any;
        level: number;
    }>();
</script>
