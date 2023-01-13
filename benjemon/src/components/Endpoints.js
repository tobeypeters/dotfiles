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

import { useRef, useState } from "react";
import { useQuery, useQueries } from "react-query";

import { grabData } from "../utility";

const baseURL = 'https://pokeapi.co/api/v2/';

 //Global for now. If no one else needs it, move it into the move function.
const extractID = inStr => inStr.replace(baseURL,'').match(/\d+/g)[0];

const buildQueries = (iterator,queryFn,enable,type) => {
    return iterator.map(m => ({
        queryKey: [{
        queryType: type,
        id: extractID(m.url)
        }],
        queryFn: queryFn,
        enabled: enable }));
}

//#region Endpoints
export function Endpoints(limit,offset=0) {
    const listQueryFn = async ({ queryKey: [ {limit, url_part} ] }) => {
        const res = await grabData(`${baseURL}${url_part}?offset=${offset}&limit=${limit}`);
        return res.results;
    }

    const char_detailQueryFn = async ({ queryKey: [{ id }] }) => {
        const res = await grabData(`${baseURL}pokemon/${id}`);

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

    const moves_detailQueryFn = async ({ queryKey: [{ id }] }) => {
        const res = await grabData(`${baseURL}move/${id}`);
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

    const [ chardata, Setchardata ] = useState(false);
    const [ movedata, Setmovedata ] = useState(false);

    let loadCharsAllowed = !chardata;
    let loadMovesAllowed = loadCharsAllowed && !movedata;

    let { data: char_data, IsError: IsCharError,
          error: char_error, isSuccess: isCharSuccess } = useQuery({
        queryKey: [{queryType: 'charList', limit, url_part: `pokemon-species`, offset: {offset} }],
        queryFn: listQueryFn,
    }, { enabled: loadCharsAllowed });

    IsCharError && console.log(`Char Error: ${char_error.message}`);

    let { data: moves_data, IsError: IsMovesError,
          error: moves_error, isSuccess: isMovesSuccess
          } = useQuery({
        queryKey: [{queryType: 'movesList', limit, url_part: 'move' }],
        queryFn: listQueryFn,
    }, { enabled: loadMovesAllowed });

    IsMovesError && console.log(`Moves Error: ${moves_error.message}`);

    loadCharsAllowed = loadCharsAllowed && (isCharSuccess && !!char_data);
    const char_listDetailQueries = buildQueries(char_data ? char_data : [],
        char_detailQueryFn, loadCharsAllowed, 'charDetail');

    loadMovesAllowed = loadMovesAllowed && (isMovesSuccess && !!moves_data);
    const moves_listDetailQueries = buildQueries(moves_data ?
        moves_data.filter(f => extractID(f.url) < 10000) : [],
        moves_detailQueryFn, loadMovesAllowed, 'moveDetail');

    let char_finalResults = useQueries(char_listDetailQueries);
    let moves_finalResults = useQueries(moves_listDetailQueries);

    loadCharsAllowed && char_finalResults.every(e =>
        e.status === 'success') && Setchardata(true);

    loadMovesAllowed && moves_finalResults.every(e =>
        e.status === 'success') && Setmovedata(true);
}
//#endregion Endpoints

//#region CacheExtract
export function CacheExtract(qClient, filter='queryType', forWhat='') {
    //Sample Query Key : [{"id":"2","queryType":"charDetail"}]
    //CacheExtract(useQueryClient(),undefined,'charDetail');

    const queryKeys = qClient.getQueryCache()
    .getAll().map(m => m.queryKey);

    console.log('Extracting cache data ...');

    const filterKeys = (type) => queryKeys.map(m => m[0])
            .filter(f => f[filter] === type);
    const filterData = (keys) => keys.map(m => qClient
                            .getQueriesData([m])[0][1]);
    const res = filterData(filterKeys(forWhat));

    return res.every(e => e !== undefined) ? res : [];
}
//#endregion CacheExtract