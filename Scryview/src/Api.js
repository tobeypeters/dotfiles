import { useQuery } from '@tanstack/react-query';

// Constants
export const baseUrl = 'https://api.scryfall.com/';
export const diamond = ' ♦ ';

export const arr_layouts = {
  art_series: 'double_sided',
  reversible_card: 'double_sided',
  transform: 'double_sided',
  modal_dfc: 'double_sided',
  double_faced_token: 'double-sided',
  split: 'split',
  flip: 'flip',
  meld: 'meld',
  leveler: 'leveler',
  class: 'enchantment',
  case: 'enchantment',
  saga: 'saga',
  adventure: 'adventure',
  mutate: 'mutate',
  prototype: 'prototype',
  battle: 'battle',
  planar: 'planar',
  scheme: 'scheme',
  vanguard: 'vanguard',
  token: 'token',
  emblem: 'emblem',
  augment: 'augment',
  host: 'host'
};

// Cache variables
let bulkDataCache = null;
let bulkDataSets = null;
let bulkDataTypes = null;
let bulkDataCardTypes = null;

// Query keys
export const queryKeys = {
  allCards: ['all-cards'],
  sets: ['magic-sets'],
  setTypes: ['set-types'],
  cardTypes: ['card-types'],
  setCards: (setCode, page) => ['set-cards', setCode, page],
  cardSearch: (name, oracle, set, type, colorsKey) =>
  ['cardSearch', name, oracle, set, type, colorsKey],
  cardSymbols: ['card-symbols']
};

// Helper functions
const fetchScryfall = async (endpoint, signal) => {
  try {
    const response = await fetch(`${baseUrl}${endpoint}`, {
      signal,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Scryvalley/1.0'
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status} - ${response.statusText}`);
    }

    return await response.json();
  } catch (error) {
  }
};

const fetchBulkDataInfo = async (signal) => {
  try {
    const response = await fetch(`${baseUrl}bulk-data`, { signal });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();
    if (data?.object !== 'list' || !Array.isArray(data.data)) {
      throw new Error('Invalid bulk data response');
    }

    const defaultCards = data.data.find(e => e.type === 'default_cards');
    if (!defaultCards?.download_uri) {
      throw new Error('Missing download URI in default cards');
    }

    return defaultCards;
  } catch (error) {
  }
};

const fetchAllCards = async ({ signal } = {}) => {
  try {
    if (bulkDataCache) return bulkDataCache;

    const bulkDataInfo = await fetchBulkDataInfo(signal);
    const response = await fetch(bulkDataInfo.download_uri, { signal });

    if (!response.ok) {
      throw new Error(`Failed to download bulk data (${response.status})`);
    }

    const cards = await response.json();
    if (!Array.isArray(cards)) {
      throw new Error('Cards data is not an array');
    }

    bulkDataCache = cards;
    return cards;
  } catch (error) {
    bulkDataCache = null;
  }
};

// Cache management
export const clearApiCache = () => {
  bulkDataCache = null;
  bulkDataSets = null;
  bulkDataTypes = null;
  bulkDataCardTypes = null;
};

export const useAllCards = () => {
  return useQuery({
    queryKey: queryKeys.allCards,
    queryFn: async ({ signal }) => fetchAllCards({ signal }),
    retry: 2,
    staleTime: 5 * 60 * 1000 // 5 minutes
  });
};

export const useSets = () => {
  const { data: allCards, isLoading, error } = useAllCards();

  return useQuery({
    queryKey: queryKeys.sets,
    queryFn: () => {
      if (!allCards) return { data: [], status: 'success' };
      if (bulkDataSets) return { data: bulkDataSets, status: 'success' };

      const setMap = new Map();
      allCards.forEach(card => {
        if (card?.set && card.set_name && !setMap.has(card.set)) {
          setMap.set(card.set, {
            code: card.set,
            name: card.set_name,
            released_at: card.released_at,
            set_type: card.set_type,
            icon_svg_uri: `https://svgs.scryfall.io/sets/${card.set}.svg`,
          });
        }
      });

      bulkDataSets = Array.from(setMap.values()).sort((a, b) =>
        new Date(a.released_at) - new Date(b.released_at)
      );
      return { data: bulkDataSets, status: 'success' };
    },
    enabled: !!allCards && !isLoading && !error,
  });
};

export const useSetTypes = () => {
  const { data: allCards } = useAllCards();

  return useQuery({
    queryKey: queryKeys.setTypes,
    queryFn: () => {
      if (bulkDataTypes) return { data: bulkDataTypes, status: 'success' };
      if (!allCards) return { data: [], status: 'success' };

      const types = new Set();
      allCards.forEach(card => {
        if (card?.set_type) types.add(card.set_type);
      });

      bulkDataTypes = Array.from(types)
        .sort()
        .map(type => ({
          value: type,
          label: type.charAt(0).toUpperCase() + type.slice(1).replace(/_/g, ' ')
        }));

      return { data: bulkDataTypes, status: 'success' };
    },
    enabled: !!allCards,
    staleTime: Infinity
  });
};

const getFilteredCardTypes = (cards) => {
  if (bulkDataCardTypes) return bulkDataCardTypes;
  if (!Array.isArray(cards)) return [];

  const typeSet = new Set();

  cards.forEach(card => {
    const typeLine = card.type_line || '';
    const words = typeLine
      .split(/[\s—–\-/]+/)
      .map(word => word.replace(/[,.'"`]/g, '').trim())
      .filter(word => word.length > 0 && !['the', 'and', 'or', 'of', 'a', 'an', 'to'].includes(word.toLowerCase()));

    words.forEach(word => typeSet.add(word));
  });

  bulkDataCardTypes = Array.from(typeSet).sort((a, b) => a.localeCompare(b));
  return bulkDataCardTypes;
};

export const useCardTypes = () => {
  const { data: allCards } = useAllCards();

  return useQuery({
    queryKey: queryKeys.cardTypes,
    queryFn: () => {
      if (!allCards) return { data: [], status: 'success' };
      const types = getFilteredCardTypes(allCards);
      return {
        data: types.map(type => ({ value: type, label: type })),
        status: 'success'
      };
    },
    enabled: !!allCards,
    staleTime: Infinity
  });
};

export const useCardsInSet = (setCode, page = 1, pageSize = 64) => {
  const { data: allCards } = useAllCards();

  return useQuery({
    queryKey: queryKeys.setCards(setCode, page),
    queryFn: () => {
      if (!setCode || !allCards) {
        return {
          data: [],
          has_more: false,
          total_pages: 0,
          total_cards: 0,
          status: 'success'
        };
      }

      const filteredCards = allCards.filter(card =>
        card.set === setCode && card.variation !== true
      );

      const sortedCards = [...filteredCards].sort((a, b) => {
        const aNum = parseInt(a.collector_number, 10) || 0;
        const bNum = parseInt(b.collector_number, 10) || 0;
        return aNum - bNum || a.name.localeCompare(b.name);
      });

      const totalCards = sortedCards.length;
      return {
        data: sortedCards.slice((page - 1) * pageSize, page * pageSize),
        has_more: page * pageSize < totalCards,
        total_pages: Math.ceil(totalCards / pageSize),
        total_cards: totalCards,
        status: 'success'
      };
    },
    enabled: !!setCode && !!allCards,
    keepPreviousData: true,
  });
};

export const useCardSearch = ({
  name = '',
  oracle = '',
  set = '',
  type = '',
  colors = []
}) => {
  const { data: allCards } = useAllCards();

  return useQuery({
    queryKey: queryKeys.cardSearch(name, oracle, set, type, colors.join('')),

    queryFn: () => {
      if (!allCards) return { data: [], status: 'success' };

      const searchTerm = (term) => term.trim().toLowerCase();
      let results = [...allCards]; // Create a copy to avoid mutation

      // Standard filters
      if (name) results = results.filter(card => card.name?.toLowerCase().includes(searchTerm(name)));
      if (oracle) results = results.filter(card => card.oracle_text?.toLowerCase().includes(searchTerm(oracle)));
      if (set) results = results.filter(card => card.set?.toLowerCase().includes(searchTerm(set)));
      if (type) results = results.filter(card => card.type_line?.toLowerCase().includes(searchTerm(type)));

      // Color filter (OR logic) - fixed implementation
      if (colors.length > 0) {
        results = results.filter(card => {
          // Check both colors and color_identity to be thorough
          const cardColors = card.colors || card.color_identity || [];

          return colors.some(color =>
            cardColors.map(c => c.toUpperCase()).includes(color.toUpperCase())
          );
        });
      }

      // Final processing
      results = results
        .filter(card => card.variation !== true)
        .sort((a, b) => {
          const aNum = parseInt(a.collector_number, 10) || 0;
          const bNum = parseInt(b.collector_number, 10) || 0;
          return aNum - bNum || a.name.localeCompare(b.name);
        });

      return {
        data: results,
        status: 'success',
        meta: {
          totalResults: results.length,
          colorsSearched: colors.length > 0
        }
      };
    },
    enabled: !!allCards && (!!name || !!oracle || !!set || !!type || colors.length > 0),
    keepPreviousData: true
  });
};

export const useCardSymbols = () => {
  return useQuery({
    queryKey: queryKeys.cardSymbols,
    queryFn: async ({ signal }) => {
      try {
        const data = await fetchScryfall('symbology', signal);
        return { data: data.data || [], status: 'success' };
      } catch (error) {
      }
    },
    staleTime: 24 * 60 * 60 * 1000, // 24 hours
    refetchOnWindowFocus: false
  });
};

export const renderManaSymbols = (text, symbols = []) => {
  if (!text) return null;

  return text.split(/(\{.*?\})/g).map((part, i) => {
    const match = part.match(/^\{(.+?)\}$/);
    if (!match) return <span key={i}>{part}</span>;

    const symbol = symbols.find(s => s.symbol === part);
    if (!symbol) return <span key={i}>{part}</span>;

    return (
      <span key={i} className='mana-symbol-wrapper'>
        <img
          src={symbol.svg_uri}
          alt={`{${match[1]}}`}
          title={symbol.english || symbol.symbol}
          className='mana-symbol'
          loading='lazy'
          style={{ height: '1em', verticalAlign: 'text-bottom' }}
          onError={(e) => {
            e.target.onerror = null;
            e.target.src = 'fallback-symbol.svg';
          }}
        />
      </span>
    );
  });
};