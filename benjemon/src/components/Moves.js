import { useQuery, useQueries } from "react-query";

// import { grabData } from "../utilities";
import { baseURL } from "../App"

// const baseURL = 'https://pokeapi.co/api/v2/';

const grabData = async (url) => {
    let response = await fetch(url);
    let results = response.status === 200 ? await response.json() : null
    return results;
}
export function useMovesQuery(limit) {
    const listQueryFn = async ({ queryKey: [{ limit }] }) => {
        const res = await grabData(`${baseURL}move?limit=${limit}`);
        return res.results;
    }

    const detailQueryFn = async ({ queryKey: [{ moveUrl }] }) => {
    const res = await grabData(moveUrl);
    const flavor_text = res
                        .flavor_text_entries
                        .filter((f => f.language.name === 'en')[0])
                        .flavor_text
                        .replace('\n',' ');
        return {
            id: res.id,
            name: res.name,
            accuracy: res.accuracy,
            damage_class: res.damage_class.name,
            flavor_text,
            power: res.power,
            pp: res.pp,
        };
    }

    const listQueryKey = [{queryType: 'movesList', limit }];
    const {isLoading: isMovesLoading, data: movesData} = useQuery({
        queryKey: listQueryKey,
        queryFn: listQueryFn,
    });
    const moveDetailQueries = (movesData ? movesData : []).map(m => ({
       queryKey: [{
         queryType: 'movesDetail',
         moveName: m.name,
         moveUrl: m.url
       }],
       queryFn: detailQueryFn,
       enabled: !isMovesLoading && !!movesData,
    }));
    return useQueries(moveDetailQueries);
}
