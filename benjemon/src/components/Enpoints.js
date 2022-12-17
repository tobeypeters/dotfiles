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

import { useState } from "react";
import { useQuery, useQueries, useQueryClient, QueryClient } from "react-query";

import { arrClear, grabData } from "../utility";

import { baseURL } from "../App"

// const baseURL = 'https://pokeapi.co/api/v2/';

 //Global for now. If no one else needs it, move it into the move function.
const extractID = inStr => inStr.replace(baseURL,'').match(/\d+/g)[0];

//#region Characters
//         /*
//           abilities, base_experience
//           forms, game_indices
//           height, held_items
//           id, is_default
//           location_area_encounters, moves
//           name, order
//           past_types, species,
//           sprites, stats,
//           types,weight
//         */

export function useCharactersQuery(limit) {
    const listQueryFn = async ({ queryKey: [{ limit }] }) => {
        const res = await grabData(`${baseURL}pokemon-species?limit=${limit}`);
        return res.results;
    }

    const listQueryKey = [{queryType: 'charList', limit }];

    const { data, IsError, error, isSuccess } = useQuery({
        queryKey: listQueryKey,
        queryFn: listQueryFn,
    });

    const detailQueryFn = async (id) => {
        const res = await grabData(`${baseURL}pokemon/${id.queryKey[0].id}`);

        return ({
            id: res.id,
            name: res.name,
            height: res.height,
            weight: res.weight,

            sprites: [
            [`${'https://assets.pokemon.com/assets/cms2/img/pokedex/full/'}${res.id.toString().padStart(3,'0')}.png`, 'Front Default'],
            // [p.sprites['front_default'], 'Front Default'],
            [res.sprites['back_default'], 'Back Default' ],
            [res.sprites['front_shiny'], 'Front Shiny' ],
            [res.sprites['back_shiny'], 'Back Shiny' ],

            /*
            [p.sprites['front_female'], 'Front Female' ],
            [p.sprites['back_female'], 'Back Female' ],
            [p.sprites['front_shiny_female'], 'Front Shiny Female' ],
            [p.sprites['back_shiny_female'], 'Back Shiny Female' ],
            */
            ],

            abilities: res.abilities
                        .filter(f => !f.is_hidden)
                        .map(m => m.ability.name), //Detail in lookup table

            base_experience: res.base_experience,
            forms: res.forms, //Use to get version_group
            held_items: res.held_items.map(a => a.item.name), //Detail in lookup table
            types: res.types.map(t => {
                return {
                    slot: t.slot,
                    name: t.type.name,
                }
            }), //Detail in lookup table

            location_area_encounters: res.location_area_encounters,

            moves: res.moves.map(m => {
                return { name: m.move.name,
                           vg: m.version_group_details } })
                    .map(m => { return { name: m.name,
                                vg: m.vg.filter(f => f.level_learned_at === 0) }})
                    .filter(f => f.vg.length)
                    .map(m => {
                        return {
                            name: m.name,
                            vg: m.vg.map(v => v.version_group.name)
                        }
                    }), //Need to further filter after determining
                        //the correct form 'red-blue' ... etc ...

            species: res.species, //Can get detail later, is_Legendary, is_Mythical,etc ...
            stats: res.stats.map(m => { return {
                base: m.base_stat,
                effort: m.effort,
                name: m.stat.name
            } })

        })
    }

    const listDetailQueries = (data ? data : [])
        .map(m => ({
            queryKey: [{
                queryType: 'charDetail',
                id: extractID(m.url)
            }],
            queryFn: detailQueryFn,
            enabled: isSuccess && !!data
            })
        );

    const listQueryDetails = useQueries(listDetailQueries);

    if (listQueryDetails.every(e => e.status === 'success')) {
       console.log('listQueryDetails',listQueryDetails.map(q => q.data));
    }

    // if (isSuccess) return data;

}
//#endregion Characters

//#region Items
export function useItemsQuery(limi) {
}
//#endregion Items

//#region Moves
/*  Description: Moves lookup table */
export function useMovesQuery(limit) {
    const [ MoveData, SetmoveData ] = useState([]);

    const queryCache = useQueryClient();

//    console.log('MoveData',MoveData);

    const listQueryFn = async ({ queryKey: [{ limit }] }) => {
        const res = await grabData(`${baseURL}move?limit=${limit}`);
        return res.results;
    }

    const detailQueryFn = async (moveUrl) => {
        const res = await grabData(moveUrl.queryKey[0].moveUrl);
        const flavor_entries = res.flavor_text_entries
            .filter((f => f.language.name === 'en'))
            .map(m => { return { version: m.version_group.name,
                                    text: m.flavor_text
                                           .replaceAll('\n','') }
            });

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
    let loadAllowed = !MoveData.length;

    let { data, IsError: IsMovesError, error: movesError,
            isLoading: isMovesLoading, isSuccess: isMovesSuccessful
          } = useQuery({
        queryKey: listQueryKey,
        queryFn: listQueryFn,
    }, { enabled: loadAllowed });

    if (IsMovesError) console.log('movesError: ',movesError.message);

    loadAllowed = loadAllowed && (isMovesSuccessful && !!data);
    const moveDetailQueries = (data ?
        data.filter(f => extractID(f.url) < 10000) : [])
        .map(m => ({
        queryKey: [{
        queryType: 'movesDetail',
        moveName: m.name,
        moveUrl: m.url
        }],
        queryFn: detailQueryFn,
        enabled: loadAllowed }));

    let queryBundles = useQueries(moveDetailQueries);

    if (loadAllowed && queryBundles.every(e => e.status === 'success')) {
        SetmoveData(queryBundles.map(q => q.data));

        ///////////////////////////////////////////////////////////////
        //So, this looks dumb. But, ultimate goal is for these functions
        //to only get called until we have our lookup table data.
        //I don't need any data cached else where. Probably need to add
        //context logic. Also will change this to use QueryCache functions
        data = null;
        queryBundles = null;
        ///////////////////////////////////////////////////////////////
    }

    if (MoveData.length) return MoveData;

    // return queryBundles.map(q => q.data);
}
//#endregion Moves
