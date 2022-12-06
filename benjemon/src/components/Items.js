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
import { useContext, useEffect, useMemo, useRef } from 'react';

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

  // const [ state, dispatch ] = useContext(MovesContext);

  let baseMoves = useRef([]);
  let basetest = useRef([]);

  let moves = useRef([]);

  console.log('moves.current.length',moves.current.length);

  const baseBuffFetch =
    [{ queryKey:`base`,
        queryFn: async () => {
          const res = await grabData(`${baseURL}move?limit=5000`);

          for(let i = res.results.length - 1; i >= 0; i--) {
            if (res.results[i].url.includes('10001/')) {
              res.results = res.results.splice(0, i);
              break;
            }
          }

          moves.current = res.results;
        }
    }];
  useQueries(baseBuffFetch,
    {
      enabled: moves.current.length === 0, // Doesn't work ?
      refetchOnMount: false,
      refetchOnReconnect: false,
      refetchOnWindowFocus: false
    }
  );

  basetest.current = useQueries(
    moves.current.map((m,idx) => ({
      queryKey:`move${m.name}`,
      queryFn: async () => {
        const res = await grabData(m.url);
        const move = {
          id: res.id,
          name: res.name,
          accuracy: res.accuracy,
          damage_class: res.damage_class.name,
          flavor_text: res.flavor_text_entries
                      .filter((f => f.language.name === 'en'))[0].flavor_text.replace('\n',' '),
          power: res.power,
          pp: res.pp,
        };

        baseMoves.current.push(move);

        // console.log('baseMoves.current.length',baseMoves.current.length);
      }
    })),
    {
      enabled: moves.current.length === 0, //Doesn't work ?
      refetchOnMount: false,
      refetchOnReconnect: false,
      refetchOnWindowFocus: false
    }
  );

  // if (baseMoves.current.length) {
  //     dispatch({ type: "assign", payload: baseMoves.current });
  //     console.log('Update global state');
  // }

  return <></>
}
