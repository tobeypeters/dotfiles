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

/*  items.js
    Description:
        Get the various Pokémonitems.
*/
// import React from 'react'
import { useQuery, useQueries } from 'react-query'
import { useContext, useRef } from 'react';

import { baseURL } from '../App';
import { arrClear, grabData } from '../utilities';

import { MovesContext } from '../DataFarm';

export function Items() {
  // console.log(baseURL);

  const {data, status, isFetched} = useQuery('itemlookup', () => grabData(`${baseURL}item?limit=5000`));

  if (status === 'loading') { console.log('loading items...'); }
  if (status === 'error') { console.log('Items error'); }

  if (isFetched) {
    data.results.forEach(f => {
      // console.log(`f : ${f}`);
    });
  }

  return (
    <></>
    // <div>items</div>
  )
}

export function Moves() {
  console.log('four');

  // const {data} = useQuery('nope',() => grabData('https://pokeapi.co/api/v2/move/826/'));
  // console.log('rainbow',data);

  const [ state, dispatch ] = useContext(MovesContext);

  let baseBuff = useRef([]);
  let baseMoves = useRef([]);
  let basetest = useRef([]);

  const baseBuffFetch = baseBuff.length ? [] : [ { queryKey:`moves_base`,
                 queryFn: () => grabData(`${baseURL}move?limit=5000`) } ];
  let baseResults = useQueries(baseBuffFetch,
    { enabled: !baseBuff.length })

  if (!baseBuff.current.length) {
    baseBuff.current = baseResults[0]?.data?.results ?
                       baseResults[0].data.results  : [];

    arrClear(baseResults);

    for(let i = baseBuff.current.length - 1; i >= 0; i--) {
      if (baseBuff.current[i].url.includes('10001/')) {
        baseBuff.current = baseBuff.current.splice(0, i);
        break;
      }
    }
  }

  const moves = baseBuff.current.length ? baseBuff.current : [];

  basetest.current = useQueries(
    moves.map((m,idx) => ({
      queryKey:`move${m.name}`,

      // queryFn: () => grabData(`https://pokeapi.co/api/v2/move/1`)
      queryFn: () => grabData(m.url)
    })), { enabled: !basetest.current.length }
  );

  let doneLoading = basetest.current.every(e => !e.isLoading);
  console.log('basetest',doneLoading,basetest.current);

  if (doneLoading) {
    basetest.current.forEach(f => {
      const move = Array(f.data).map(p => ({
        id: p.id,
        name: p.name,
        accuracy: p.accuracy,
        damage_class: p.damage_class.name,
        flavor_text: p.flavor_text_entries
                     .filter((f => f.language.name === 'en'))[0].flavor_text.replace('\n',' '),
        power: p.power,
        pp: p.pp,
      }));

      baseMoves.current.push(move);
    });

    console.log('baseMoves',baseMoves.current);
  }

  if (baseMoves.current.length) {
      // dispatch({ type: "assign", payload: baseMoves.current });
      console.log('Update global state');
  }

  return <></>
}
