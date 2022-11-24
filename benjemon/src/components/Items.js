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
import { useState  } from 'react';

import { baseURL } from '../App';
import { cleanse } from '../utilities';


const grabData = async (url) => {
  let response = await fetch(url);
  let results = response.status === 200 ? await response.json() : null
  return results;
}

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
  // const [datamoves, setDataMoves] = useState([]);

  let databuf = [];

  console.log('four');

  const {data, status, isFetched} = useQuery('movelookup', () => grabData(`${baseURL}move?limit=5000`));

  if (status === 'loading') { console.log('loading items...'); }
  if (status === 'error') { console.log('Items error'); }

  let moves = [];

  if (isFetched) {
    let fdx = -1;

    data.results.forEach((f, idx) => {
      if (f.url.includes('10001/')) fdx = idx
    });

    if (fdx > -1) {
      console.log(`data.results.length b : ${data.results.length}`);
      data.results = data.results.splice(0, fdx);
      console.log(`data.results.length a : ${data.results.length}`);
    }

    // if (!datamoves.length) {
    //   // setDataMoves(data.results);
    //   console.log(`length ${datamoves.length} ${data.results.length}`);
    // }
  }

  moves = isFetched ? data.results : [];
  console.log(moves);
  const results = useQueries(
    moves.map(m => ({
      queryKey:`move${m.name}`,
      queryFn: () => grabData(m.url)
    })), {enabled: isFetched}
  );

  return (
    <></>
    // <div>items</div>
  )
}




      // const results = useQueries(data.map(m => {
      //   return { queryKey: `move${m.name}`,
      //             queryFn: () => grabData(m.url) };
      //   })
      // );

    // fillPromises2(promises,[`${baseURL}move/`],fdx);
    // Promise.allSettled(promises)
    // .then(res => {
    //   cleanse(promises);
    //   res.forEach(res => {
    //     if (res.status === 'fulfilled') {
    //       const move = Array(res.value).map(p => ({
    //         id: p.id,
    //         name: p.name,
    //         accuracy: p.accuracy,
    //         damage_class: p.damage_class.name,
    //         flavor_text: p.flavor_text_entries
    //                       .filter((f => f.language.name === 'en'))[0].flavor_text,
    //         power: p.power,
    //         pp: p.pp,
    //       }));

    //       bufferMove.push(move[0]);
    //     }
    //   });

    //   console.log(bufferMove);
    //   setDataMoves(bufferMove);
    // });
  // }
