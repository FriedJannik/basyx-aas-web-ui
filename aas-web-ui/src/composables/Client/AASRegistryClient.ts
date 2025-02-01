import { jsonization } from '@aas-core-works/aas-core3.0-typescript';
import { computed } from 'vue';
import { useRequestHandling } from '@/composables/RequestHandling';
import { useNavigationStore } from '@/store/NavigationStore';
import * as descriptorTypes from '@/types/Descriptors';
import { base64Encode } from '@/utils/EncodeDecodeUtils';
import { removeNullValues } from '@/utils/generalUtils';
import { stripLastCharacter } from '@/utils/StringUtils';

export function useAASRegistryClient() {
    // Stores
    const navigationStore = useNavigationStore();

    //Composables
    const { getRequest, postRequest, putRequest } = useRequestHandling();

    const endpointPath = '/shell-descriptors';

    // Computed Properties
    const aasRegistryUrl = computed(() => navigationStore.getAASRegistryURL);

    /**
     * Fetches a list of all available Asset Administration Shell (AAS) Descriptors.
     *
     * @async
     * @returns {Promise<Array<any>>} A promise that resolves to an array of AAS Descriptors.
     * An empty array is returned if the request fails or no AAS Descriptors are found.
     */
    async function fetchAasDescriptorList(): Promise<Array<any>> {
        const failResponse = [] as Array<any>;

        if (aasRegistryUrl.value.trim() === '') return failResponse;

        let aasRegUrl = aasRegistryUrl.value;
        if (aasRegUrl.trim() === '') return failResponse;
        if (aasRegUrl.endsWith('/')) aasRegUrl = stripLastCharacter(aasRegUrl);
        if (!aasRegUrl.endsWith(endpointPath)) aasRegUrl += endpointPath;

        const aasRegistryPath = aasRegUrl;
        const aasRegistryContext = 'retrieving all AAS Descriptors';
        const disableMessage = false;
        try {
            const aasRegistryResponse = await getRequest(aasRegistryPath, aasRegistryContext, disableMessage);
            if (
                aasRegistryResponse.success &&
                aasRegistryResponse.data.result &&
                aasRegistryResponse.data.result.length > 0
            ) {
                const aasDescriptors = aasRegistryResponse.data.result;
                return aasDescriptors;
            }
        } catch {
            return failResponse;
        }
        return failResponse;
    }

    /**
     * Fetches a Asset Administration Shell (AAS)  Descriptor by the provided AAS ID.
     *
     * @async
     * @param {string} aasId - The ID of the AAS Descriptor to fetch.
     * @returns {Promise<any>} A promise that resolves to an AAS Descriptor.
     */
    async function fetchAasDescriptorById(aasId: string): Promise<any> {
        const failResponse = {} as any;

        if (!aasId) return failResponse;

        aasId = aasId.trim();

        if (aasId === '') return failResponse;

        if (aasRegistryUrl.value.trim() === '') return failResponse;

        let aasRegUrl = aasRegistryUrl.value;
        if (aasRegUrl.trim() === '') return failResponse;
        if (aasRegUrl.endsWith('/')) aasRegUrl = stripLastCharacter(aasRegUrl);
        if (!aasRegUrl.endsWith(endpointPath)) aasRegUrl += endpointPath;

        const aasRegistryPath = aasRegUrl + '/' + base64Encode(aasId);
        const aasRegistryContext = 'retrieving AAS Descriptor';
        const disableMessage = false;
        try {
            const aasRegistryResponse = await getRequest(aasRegistryPath, aasRegistryContext, disableMessage);
            if (
                aasRegistryResponse?.success &&
                aasRegistryResponse?.data &&
                Object.keys(aasRegistryResponse?.data).length > 0
            ) {
                return aasRegistryResponse.data;
            }
        } catch {
            return failResponse;
        }
        return failResponse;
    }

    /**
     * Checks if Asset Administration Shell (AAS) Descriptor with provided ID is available (in registry).
     *
     * @async
     * @param {string} aasId - The ID of the AAS to check.
     * @returns {Promise<boolean>} A promise that resolves to `true` if AAS with provided ID is available, otherwise `false`.
     */
    async function isAvailableById(aasId: string): Promise<boolean> {
        const failResponse = false;

        if (!aasId) return failResponse;

        aasId = aasId.trim();

        if (aasId === '') return failResponse;

        const aasDescriptor = await fetchAasDescriptorById(aasId);

        if (aasDescriptor && Object.keys(aasDescriptor).length > 0) {
            return true;
        }

        return failResponse;
    }

    async function postAasDescriptor(aasDescriptor: descriptorTypes.AASDescriptor): Promise<void> {
        if (aasRegistryUrl.value.trim() === '') return;

        let aasRegUrl = aasRegistryUrl.value;
        if (aasRegUrl.trim() === '') return;
        if (aasRegUrl.endsWith('/')) aasRegUrl = stripLastCharacter(aasRegUrl);
        if (!aasRegUrl.endsWith(endpointPath)) aasRegUrl += endpointPath;

        const context = 'updating AAS Descriptor';
        const disableMessage = false;
        const path = aasRegUrl;
        const headers = new Headers();
        headers.append('Content-Type', 'application/json');
        const body = JSON.stringify(aasDescriptor);

        const response = await postRequest(path, body, headers, context, disableMessage);
        if (response.success) {
            navigationStore.dispatchTriggerAASListReload(); // Reload AAS List
        }
    }

    async function putAasDescriptor(aasDescriptor: descriptorTypes.AASDescriptor): Promise<void> {
        if (aasRegistryUrl.value.trim() === '') return;

        let aasRegUrl = aasRegistryUrl.value;
        if (aasRegUrl.trim() === '') return;
        if (aasRegUrl.endsWith('/')) aasRegUrl = stripLastCharacter(aasRegUrl);
        if (!aasRegUrl.endsWith(endpointPath)) aasRegUrl += endpointPath;

        const context = 'updating AAS Descriptor';
        const disableMessage = false;
        const path = aasRegUrl + '/' + base64Encode(aasDescriptor.id);
        const headers = new Headers();
        headers.append('Content-Type', 'application/json');
        const body = JSON.stringify(aasDescriptor);

        const response = await putRequest(path, body, headers, context, disableMessage);
        if (response.success) {
            navigationStore.dispatchTriggerAASListReload(); // Reload AAS List
        }
    }

    function createDescriptorFromAAS(
        aas: jsonization.JsonObject,
        endpoints: Array<descriptorTypes.Endpoint>
    ): descriptorTypes.AASDescriptor {
        const jsonAAS = JSON.stringify(aas);
        const parsedAAS = JSON.parse(jsonAAS);
        let descriptor = new descriptorTypes.AASDescriptor(
            endpoints,
            parsedAAS.id,
            parsedAAS.administration,
            parsedAAS.assetInformation?.assetKind,
            parsedAAS.assetInformation?.assetType,
            parsedAAS.description,
            parsedAAS.displayName,
            parsedAAS.extensions,
            parsedAAS.assetInformation?.globalAssetId,
            parsedAAS.idShort,
            parsedAAS.assetInformation?.specificAssetIds
        );
        descriptor = removeNullValues(descriptor);
        return descriptor;
    }

    return {
        endpointPath,
        fetchAasDescriptorList,
        fetchAasDescriptorById,
        isAvailableById,
        putAasDescriptor,
        postAasDescriptor,
        createDescriptorFromAAS,
    };
}
