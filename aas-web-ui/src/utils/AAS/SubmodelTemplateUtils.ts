export const smts = [
    {
        name: 'Digital Nameplate for industrial equipment',
        idShort: 'Nameplate',
        semanticId: 'https://admin-shell.io/zvei/nameplate/2/0/Nameplate',
        version: '2.0',
    },
    {
        name: 'Digital Nameplate for industrial equipment',
        idShort: 'Nameplate',
        semanticId: 'https://admin-shell.io/idta/nameplate/3/0/Nameplate',
        version: '3.0',
        fileName: 'DigitalNameplate_3_0.json',
    },
    {
        name: 'Carbon Footprint',
        idShort: 'CarbonFootprint',
        semanticId: 'https://admin-shell.io/idta/CarbonFootprint/CarbonFootprint/0/9',
        version: '0.9',
    },
    {
        name: 'Contact Informations',
        idShort: 'ContactInformations',
        semanticId: 'https://admin-shell.io/zvei/nameplate/1/0/ContactInformations',
        version: '1.0',
    },
    {
        name: 'Handover Documentation',
        idShort: 'HandoverDocumentation',
        semanticId: '0173-1#01-AHF578#001',
        version: '1.2',
    },
    {
        name: 'Hierarchical Structures enabling Bills of Material',
        idShort: 'HierarchicalStructures',
        semanticId: 'https://admin-shell.io/idta/HierarchicalStructures/1/0/Submodel',
        version: '1.0',
    },
    {
        name: 'Hierarchical Structures enabling Bills of Material',
        idShort: 'HierarchicalStructures',
        semanticId: 'https://admin-shell.io/idta/HierarchicalStructures/1/1/Submodel',
        version: '1.1',
    },
    {
        name: 'Generic Frame for Technical Data for Industrial Equipment in Manufacturing',
        idShort: 'TechnicalData',
        semanticId: 'https://admin-shell.io/ZVEI/TechnicalData/Submodel/1/2',
        version: '1.2',
    },
    {
        name: 'Time Series Data',
        idShort: 'TimeSeries',
        semanticId: 'https://admin-shell.io/idta/TimeSeries/1/1',
        version: '1.1',
    },
];

export async function getRequiredElements(semanticId: string): Promise<any[]> {
    return await getElementsWithCardinality(semanticId, 'One');
}

export async function getOptionalElements(semanticId: string): Promise<any[]> {
    return await getElementsWithCardinality(semanticId, 'Zero');
}

export function isSubmodelTemplate(semanticId: string): boolean {
    const smt = smts.filter((smt) => smt.semanticId === semanticId);
    return smt.length > 0;
}

async function getElementsWithCardinality(semanticId: string, cardinality: string): Promise<any[]> {
    const smt = smts.find((smt) => smt.semanticId === semanticId);
    if (!smt) return [];
    if (!Object.prototype.hasOwnProperty.call(smt, 'fileName')) return [];
    const data = await fetch('/SubmodelTemplates/' + smt.fileName);
    const json = await data.json();
    const submodelElements = json.submodels[0].submodelElements;

    const foundElements = submodelElements.filter(
        (submodelElement: any) =>
            Object.prototype.hasOwnProperty.call(submodelElement, 'qualifiers') &&
            submodelElement.qualifiers.filter(
                (qualifier: any) => qualifier.type === 'SMT/Cardinality' && qualifier.value.startsWith(cardinality)
            ).length > 0
    );
    return foundElements;
}

export async function getMissingRequiredElements(inputJsonObject: any): Promise<any[]> {
    const requiredElements = await getRequiredElements(inputJsonObject.semanticId.keys[0].value);
    if (!requiredElements) return [];
    const missingElements = requiredElements.filter((element: any) => {
        const idShort = element.idShort;
        return !inputJsonObject.submodelElements.some((submodelElement: any) => submodelElement.idShort === idShort);
    });
    return missingElements;
}

export async function getMissingOptionalElements(inputJsonObject: any): Promise<any[]> {
    const optionalElements = await getOptionalElements(inputJsonObject.semanticId.keys[0].value);
    if (!optionalElements) return [];
    const missingElements = optionalElements.filter((element: any) => {
        const idShort = element.idShort;
        return !inputJsonObject.submodelElements.some((submodelElement: any) => submodelElement.idShort === idShort);
    });
    return missingElements;
}
