// pokeAPI library : npm install pokedex-promise-v2 --save
import React, { useEffect, useRef } from 'react';

//import { useAsync } from 'react-async';

import Logo from './Logo';

// import PokemonList from './PokemonList';

const pokeURL = 'https://pokeapi.co/api/v2/pokemon?offset=0&limit=5000';

const loadPokersData = async () => {
  console.log('loadPokersData');
  const res = await fetch(pokeURL);

  if (!res.ok) throw new Error(res.statusText)

  return res.json()
}

const LoadPokers = () => {
//  console.log('LoadPokers');

const { data } = useAsync({ promiseFn: loadPokersData })
//const { data, error, isPending } = useAsync({ promiseFn: loadPokersData })
//  if (isPending) console.log("Loading...");
//  if (error) console.log(`Something went wrong: ${error.message}`);
  if (data) {
    console.log('data: [----------------');
    console.log(data.results)
    console.log('data: ----------------]');
    return data.results
  }

  return null
}

function App() {

  // const [pokemon, setPokemon] = useState([])
  // const [currentPageUrl, setCurrentPageUrl] = useState("https://pokeapi.co/api/v2/pokemon")

  // const [currentPageUrl] = useState('https://pokeapi.co/api/v2/pokemon?offset=0&limit=2000');

  // const [nextPageUrl, setNextPageUrl] = useState()
  // const [prevPageUrl, setPrevPageUrl] = useState()
  // const [loading, setLoading] = useState(true)

  const results = useRef();

  useEffect(() => {
    const pd = async () => {
      const res = await fetch(pokeURL)
                        .then(res => res.json())
                        .then(res => res.results );

      results.current = res;

    }

    console.log('gabby')
    pd();
    console.log('has')
    //if (!res.ok) throw new Error(res.statusText);
  }
  ,[]);

//const [initial, setInitial] = useState(false);

console.log('big')
console.log(results.current);
console.log('butt')

//if (results.current === undefined) {
//    console.log('butt');
//    results.current = LoadPokers();
//    console.log(results.current);
//    setInitial(true);
//}

//  const [dataLoaded, gotData] = useState(false);

//  console.log('app');

  //I can't call LoadPokers in useEffect like I want.
//  if (!dataLoaded) {
//    console.log('!dataLoaded');
//    results.current = LoadPokers();
//    console.log('dataloaded:results.current.: [-----------');
//    console.log(results);
//    console.log('dataloaded:results.current: -----------]');
//  }

// useEffect(() => {
//   //    console.log('results.current: [-----------');
//   //    console.log(results);
//   //    console.log('results.current: -----------]');
//   //    if (results.current) {
//   //      console.log('useEffect: [-----------');
//   //      console.log('useEffect');
//   //      console.log('useEffect: ------------]');
//   //        gotData(true);
//   //    }
//     },[]);

//   // console.log('results: [-----------');
//   // console.log(results.current);
//   // console.log('results: -----------]');

   return (
     <>
     <Logo />
      {/* <PokemonList pokemon={pokemon} /> */}
      <br />
    </>
 )

}

export default App;
