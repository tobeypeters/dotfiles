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

/*  App.js
    Description:
        Unoffical Pokémon Pokédex.  This is a personal project. I don't plan on
        letting anyone else use it, except for family.
    Copyright Info:
        All property [ images & data ] belong and are registered trademarks and such, of the following companies:
          The Pokémon Company : Internation - http://www.pokemon.com
          Nintendo of America, Inc - http://www.nintendo.com
        NOTE: Data is being pulled from http://www.pokeapi.co
    Resources:
        Javascript library: npm install pokedex-promise-v2 --save
        Sprites:
          pokeApi provides sprites, but are lower quality. They are good, don't get me wrong.
          Official (Hi-Res) : https://assets.pokemon.com/assets/cms2/img/pokedex/full/001.png
                              https://assets.pokemon.com/assets/cms2/img/pokedex/detail/012.png
          https://cardmavin.com/media-category/pokemon-set-symbols
        Misc:
          https://stackoverflow.com/questions/26736209/how-do-i-stop-animation-in-html-and-css
          https://loading.io/css/
          https://www.tiktok.com/@thesnikle/video/7036799720718650670?is_from_webapp=1&sender_device=pc&web_id=7164190503155566126
*/

import { useMemo } from 'react';
import { useQueryClient } from 'react-query';

import Logo from './Logo';
// import Spinner from './Spinner';

// import {  useMovesQuery,
//          useCharactersQuery } from './components';

import { useEndpoints } from './components';

import { Charlist } from './components';

function App() {
  useEndpoints(10000);

  const queryClient = useQueryClient();
  const queryKeys = queryClient.getQueryCache()
                               .getAll().map(m => m.queryKey);

//#region Data
  const  [chars, moves] = useMemo(() => {
    const filterKeys = (type) => queryKeys.map(m => m[0])
                                 .filter(f => f['queryType'] === type);
    const filterData = (keys) => keys.map(m => queryClient
                                               .getQueriesData([m])[0][1]);

    const charRes = filterData(filterKeys('charDetail'));
    const moveRes = filterData(filterKeys('moveDetail'));

    return [
      charRes.every(e => e !== undefined) ? charRes : [],
      moveRes.every(e => e !== undefined) ? moveRes : []
    ]

  },[ queryClient, queryKeys ]);

  // if (chars.length) console.log('chars',chars);
  // if (moves.length) console.log('moves',moves);
//#endregion Data

  return (
    <div className="App">
      <Logo />
      <div>
      { chars.length ? <Charlist data={ chars } /> : (<></>) }
      </div>
    </div>
  )

}

export default App;