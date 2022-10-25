import React from 'react'

import styles from './App.module.css'

import PokeCard from './PokeCard'

export default function PokemonList({ pokemon }) {
  return (
    <div className={styles.pokeContainer}>
      {
        (pokemon.map(p => ( <PokeCard pokechar={p} /> )))
      }
    </div>
  )
}
