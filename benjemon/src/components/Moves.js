import { useQuery, useQueries } from "react-query";

// import { grabData } from "../utilities";
import { baseURL } from "../App"

// const baseURL = 'https://pokeapi.co/api/v2/';

const grabData = async (url) => {
    let response = await fetch(url);
    let results = response.status === 200 ? await response.json() : null
    return results;
}

const zipQueries = (queries,bundles) => queries.map(
(query,i) => ({ query, bundle: bundles[i] })
);

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

    const moveDetailQueries = (movesData ?
        movesData.filter(f => f.url.replace(baseURL,'')
        .match(/(\d+)/)[0] < 10000) : [])
        .map(m => ({
        queryKey: [{
        queryType: 'movesDetail',
        moveName: m.name,
        moveUrl: m.url
        }],
        queryFn: detailQueryFn,
        enabled: !isMovesLoading && !!movesData,
    }));

    // return useQueries(moveDetailQueries);
    const queryBundles = useQueries(moveDetailQueries);

    // console.log('moveDetailQueries',moveDetailQueries2);
    // console.log('queryBundles',queryBundles);

    return zipQueries(moveDetailQueries, queryBundles);
}
