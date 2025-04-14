export type SubmodelTemplateMetadata = {
    id: string;
    fileName: string;
};

export function getSubmodelTemplateMapping(): SubmodelTemplateMetadata[] {
    return [{ id: 'Digital Nameplate 3.0', fileName: 'DigitalNameplate_3_0.json' }];
}
