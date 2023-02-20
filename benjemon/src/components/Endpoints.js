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
import { useQuery, useQueryClient } from "react-query";

import { grabData } from "../utility";

const baseURL = 'https://pokeapi.co/api/v2/';

const extractID = inStr => inStr.replace(baseURL,'').match(/\d+/g)[0];

//If obj is null return a str specifying that, else return the orig obj.
const nullObj = (obj) => obj ? obj : '<not specified>';

const nofluff = (str) => {
    //Let's make the data prettier
    str = str.replace(new RegExp('ball', 'i'),'ball');
    str = str.replace(new RegExp('poké ', 'i'),'Poké ');
    str = str.replace(new RegExp('pokémon', 'i'),'Pokémon');
    str = str.replace(new RegExp('great ball', 'i'),'Great Ball');
    str = str.replace(new RegExp('pokémon ball', 'i'),'Pokémon Ball');
    str = str.replaceAll('\n',' ');
    str = str.replace(/\s+/g,' ');
    return str;
}

//#region CacheExtract
export function CacheExtract(qClient, filter='queryType', forWhat='') {
    //Sample Query Key : [{"id":"2","queryType":"charDetail"}]
    //CacheExtract(useQueryClient(),undefined,'charDetail');

    const queryKeys = qClient.getQueryCache()
    .getAll().map(m => m.queryKey);

    const filterKeys = (type) => queryKeys.map(m => m[0])
            .filter(f => f[filter] === type);
    const filterData = (keys) => keys.map(m => qClient
                            .getQueriesData([m])[0][1]);
    const res = filterData(filterKeys(forWhat));

    return res.every(e => e !== undefined) ? res : [];
}
//#endregion CacheExtract

//#region Endpoints
export async function Endpoints(limit,offset=0) {
    const groupFlavorText = (arr) => {
        const results = [];

        arr.forEach(f => {
            const res = results.find(resultValue => resultValue.text === f.text);

            f.text = nofluff(f.text);

            if (!res) {
              results.push(f);
            } else {
              res.version.push(...f.version);
            }
        })

        return results;
    }

    const buildQueries = (iterator,queryFn,enable,type) => {
        return iterator.map(m => ({
            queryKey: [{
            queryType: type,
            id: extractID(m.url)
            }],
            queryFn: queryFn,
        }));
    }

    const uqc = useQueryClient();

    const listQueryFn = async ({ queryKey: [ {limit, url_part} ] }) => {
        const res = await grabData(`${baseURL}${url_part}?offset=${offset}&limit=${limit}`);
        return res.results;
    }

    const char_detailQueryFn = async ({ queryKey: [{ id }] }) => {
        const res = await grabData(`${baseURL}pokemon/${id}`);

        if (res.types.length === 1) res.types.push(
            {slot: 999, type: {name: 'normal'}}
        );

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
        const flavor_entries = groupFlavorText(res.flavor_text_entries
        .filter(f => f.language.name === 'en')
        .map(m => ({ version: [m.version_group.name],
                        text: nofluff(m.flavor_text)})));

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

    const items_detailQueryFn = async ({ queryKey: [{ id }] }) => {
        const res = await grabData(`${baseURL}item/${id}`);
        const flavor_entries = groupFlavorText(res.flavor_text_entries
        .filter(f => f.language.name === 'en')
        .map(m => ({text: nofluff(m.text),
                 version: [m.version_group.name]})));

        const effect_entries = res.effect_entries
        .filter(f => f.language.name === 'en')
        .map(m => ({ effect: nofluff(m.effect),
               short_effect: nofluff(m.short_effect) }));

        return ({
            name: res.name,
            attributes: res.attributes.map(m => m.name),
            category: res.category.name,
            cost: res.cost,
            effect_entries,
            flavor_entries: flavor_entries,
            fling_effect: nullObj(res.fling_effect),
            fling_power: nullObj(res.fling_power),
            sprites: res.sprites,
        })
    }

    const [ chardata, Setchardata ] = useState(true);
    const [ movedata, Setmovedata ] = useState(true);
    const [ itemdata, Setitemdata ] = useState(true);

    let loadCharsAllowed = chardata;
    let loadMovesAllowed = !loadCharsAllowed && movedata;
    let loadItemsAllowed = !loadMovesAllowed && itemdata;

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

    let { data: items_data, IsError: IsItemsError,
          error: items_error, isSuccess: isItemsSuccess
        } = useQuery({
        queryKey: [{queryType: 'itemsList', limit, url_part: 'item' }],
        queryFn: listQueryFn,
    }, { enabled: loadItemsAllowed });

    IsItemsError && console.log(`Items Error: ${items_error.message}`);

    loadCharsAllowed = loadCharsAllowed && isCharSuccess;
    const char_listDetailQueries = buildQueries(char_data ? char_data : [],
        char_detailQueryFn, loadCharsAllowed, 'charDetail');

    loadMovesAllowed = loadMovesAllowed && isMovesSuccess;
    const moves_listDetailQueries = buildQueries(moves_data ?
        moves_data.filter(f => extractID(f.url) < 10000) : [],
        moves_detailQueryFn, loadMovesAllowed, 'moveDetail');

    loadItemsAllowed = loadItemsAllowed && isItemsSuccess;
    const items_listDetailQueries = buildQueries(items_data ?
        items_data.filter(f => extractID(f.url) < 10000) : [],
        items_detailQueryFn, loadItemsAllowed, 'itemDetail');

    if (loadCharsAllowed && chardata) {
        const gc = Math.max(char_listDetailQueries.length / 5, 1);
        for (let i = 0; i < char_listDetailQueries.length - 1;i += gc - 1)
        {
            const currentBatch = char_listDetailQueries.slice(i, i + gc);
            await Promise.allSettled(currentBatch.map(query => uqc.prefetchQuery(query)));
        }

        Setchardata(false);
    }

    if (loadMovesAllowed && movedata) {
        const gc = Math.max(moves_listDetailQueries.length / 5, 1);
        for (let i = 0; i < moves_listDetailQueries.length - 1;i += gc - 1)
        {
            const currentBatch = moves_listDetailQueries.slice(i, i + gc);
            await Promise.allSettled(currentBatch.map(query => uqc.prefetchQuery(query)));
        }

        Setmovedata(false);
    }

    if (loadItemsAllowed && itemdata) {
        const gc = Math.max(items_listDetailQueries.length / 5, 1);
        for (let i = 0; i < items_listDetailQueries.length - 1;i += gc - 1)
        {
            const currentBatch = items_listDetailQueries.slice(i, i + gc);
            await Promise.allSettled(currentBatch.map(query => uqc.prefetchQuery(query)));
        }

        Setitemdata(false);
    }
}
//#endregion Endpoints
