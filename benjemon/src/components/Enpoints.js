/*
    The MIT License(MIT)
    Copyright(c), Tobey Peters, https://github.com/tobeypeters
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software
    and associated documentation files (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*  Endpoints.js
    Description:
        Houses all the data endpoints.
*/
import { useQuery, useQueries } from "react-query";

// import { grabData } from "../utilities";
import { baseURL } from "../App"

// const baseURL = 'https://pokeapi.co/api/v2/';

const grabData = async (url) => {
    let response = await fetch(url);

    // console.log('response',response);

    let results = response.status === 200 ? await response.json() : [];
    return results;
}

//#region Items
export function useItemsQuery(limit) {
}
//#endregion Items

//#region Moves
/*  Description: Moves lookup table */
export function useMovesQuery(limit) {
    const listQueryFn = async ({ queryKey: [{ limit }] }) => {
        const res = await grabData(`${baseURL}move?limit=${limit}`);
        return res.results;
    }

    const detailQueryFn = async (moveUrl) => {
        // console.log('moveUrl',moveUrl.queryKey[0].moveUrl);

        const res = await grabData(moveUrl.queryKey[0].moveUrl);
        // console.log('res',res);
        const flavor_entries = res.flavor_text_entries
            .filter((f => f.language.name === 'en'))
            .map(m => { return { version: m.version_group.name,
                                    text: m.flavor_text
                                           .replaceAll('\n','') }
            });

        console.log('flavor_text',flavor_entries);

        return ({
            id: res.id,
            name: res.name,
            accuracy: res.accuracy,
            damage_class: res.damage_class.name,
            flavor_entries,
            power: res.power,
            pp: res.pp,
        })
    }

    const listQueryKey = [{queryType: 'movesList', limit }];

//    const {isLoading: isMovesLoading, data: movesData} = useQuery({
    const { data: movesData, IsError: IsMovesError, error: movesError,
            isLoading: isMovesLoading, isSuccess: isMovesSuccessful
          } = useQuery({
        queryKey: listQueryKey,
        queryFn: listQueryFn,
    });

    if (IsMovesError) console.log('movesError: ',movesError.message);

    const moveDetailQueries = (movesData ?
        movesData.filter(f => f.url.replace(baseURL,'')
        .match(/\d+/g)[0] < 10000) : [])
        .map(m => ({
        queryKey: [{
        queryType: 'movesDetail',
        moveName: m.name,
        moveUrl: m.url
        }],
        queryFn: detailQueryFn,
        enabled: isMovesSuccessful && !!movesData
    }));

    const queryBundles = useQueries(moveDetailQueries);

    if (queryBundles.every(e => e.status === 'success')) {
        return queryBundles.map(q => q.data);
    }
}
//#endregion Moves
