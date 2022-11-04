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

        Misc:
          https://stackoverflow.com/questions/26736209/how-do-i-stop-animation-in-html-and-css
          https://loading.io/css/
*/

import React, { useEffect, useState } from 'react';

import Logo from './Logo';
import PokemonList from './PokemonList';
import Spinner from './Spinner';

function App() {
  const pokeURL = 'https://pokeapi.co/api/v2/pokemon-species?limit=5000';

  const [data, setData] = useState([]);

  useEffect(() => {
    //Right now, only get data once
    const getData = async () => {

      const promises = [];
      const forms = []
      let bufferA = [];

      const fillPromises = (buffer, url, count) => {
        for (let i = 1; i <= count; i++) {
          buffer.push(
            fetch(`${url}${i}`)
              .catch(err => { console.log(`catch err : ${err}`) })
              .then(res => {
                if (res.status >= 200 && res.status <= 299)
                  return res.json();
              } // res
              ) // then
          )
        } // for
      }

      const getDataItem = async (url) => {
        const res = await fetch(url)
        if (res.ok)
          return await res.json();
      }

      let response = await fetch(pokeURL);
      if (response.ok) {
        let result = await response.json();

        //fillPromises(promises,'https://pokeapi.co/api/v2/pokemon/',result.results.length);
        // fillPromises(forms,'https://pokeapi.co/api/v2/pokemon-form/',result.results.length);

/*  abilities, base_experience
    forms, game_indices
    height, held_items
    id, is_default
    location_area_encounters, moves
    name, order
    past_types, species,
    sprites, stats,
    types,weight
*/
        fillPromises(promises,'https://pokeapi.co/api/v2/pokemon/',result.results.length);
        Promise.allSettled(promises)
          .then(results => {
            results.forEach(res => {
              if (res.status === "fulfilled") {
                const pokemon = Array(res.value).map(p => ({
                  id: p.id,
                  is_default: p.is_default,
                  name: p.name,
                  height: p.height,
                  weight: p.weight,

                  sprites: [
                    [`${'https://assets.pokemon.com/assets/cms2/img/pokedex/full/'}${p.id.toString().padStart(3,'0')}.png`, 'Front Default'],
                    // [p.sprites['front_default'], 'Front Default'],
                    [p.sprites['back_default'], 'Back Default' ],
                    [p.sprites['front_shiny'], 'Front Shiny' ],
                    [p.sprites['back_shiny'], 'Back Shiny' ],

                    /*
                    [p.sprites['front_female'], 'Front Female' ],
                    [p.sprites['back_female'], 'Back Female' ],
                    [p.sprites['front_shiny_female'], 'Front Shiny Female' ],
                    [p.sprites['back_shiny_female'], 'Back Shiny Female' ],
                    */
                  ],

                  abilities: p.abilities
                              .filter(a => !a.is_hidden)
                              .map(a => a.ability.name).join(', '),

                  base_experience: p.base_experience,
                  forms: p.forms,
                  formName: 'none',
                  game_indices: p.game_indices,
                  held_items: p.held_items,
                  types: p.types.map((type) => type.type.name).join(', '),
                  location_area_encounters: p.location_area_encounters,
                  moves: p.moves,
                  order: p.order,
                  past_types: p.past_types,
                  species: p.species,
                  stats: p.stats,
                  stir: 'big',
                }));

                bufferA.push(pokemon);

              } // if
            }); // forEach

            // bufferA.forEach(async (f, idx) => {
            //   const res = await getDataItem(`https://pokeapi.co/api/v2/pokemon-form/${f[0].id}`);
            //   f[0].formName = res.version_group.name.replace('-', ' & ');
            //   console.log(`forEach: ${f[0].formName}`);
            // }
            // );
            // bufferA.forEach(f => {
            //     console.log(f[0].formName);
            //  });

            // setData(bufferA);

            // promises.slice(0, promises.length);
            // bufferA.slice(0, bufferA.length);

          }) // then
          .then (res => {
            promises.slice(0, promises.length);

            fillPromises(promises,'https://pokeapi.co/api/v2/pokemon-form/',result.results.length);
            Promise.allSettled(promises)
            .then (results => {
              results.forEach(res => {
                if (res.status === "fulfilled") {
                  console.log(`${res.status} res.value.version_group : ${res.value.version_group}`);
                  //bufferA[res.value.id - 1][0].formName = res.value.version_group.name;
                }
              })

              setData(bufferA)
            })

            // results.forEach(async (f, idx) => {
            //     const res = await getDataItem(`https://pokeapi.co/api/v2/pokemon-form/${f[0].id}`);
            //     f[0].formName = res.version_group.name.replace('-', ' & ');
            //     console.log(`forEach: ${f[0].formName}`);
            // }); // forEach



          }) // form then

      } // response.ok

}; //getData
    getData();
},[]); //useEffect

  return (
    <div className="App">
      <Logo />
      <br />

      <div>
        {data.length ? (
          <PokemonList pokemon={data}/>
        ) : (
          <Spinner />)}
      </div>
    </div> // App
 )

}

export default App;