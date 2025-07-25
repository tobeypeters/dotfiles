import { useEffect, useState, useMemo } from 'react';
import PropTypes from 'prop-types';
import {
  useAllCards,
  useCardSearch,
  useCardSymbols,
  useSets,
  renderManaSymbols,
  diamond,
  arr_layouts
} from '../Api';
import { paginate } from './Paginate';
import { hexToRgb, darkenColor, lightenColor } from '../Utility';

export function CardGallery({
  setCode,
  searchFields = {},
  onSelectSet,
  selectedCardType,
  selectedColors = []
}) {
  const [page, setPage] = useState(1);
  const [selectedCard, setSelectedCard] = useState(null);
  const [cardFaceIndex, setCardFaceIndex] = useState(0);

  const isSearching = !!(searchFields.name || searchFields.oracle || searchFields.type || selectedCardType || selectedColors.length > 0);

  // Fetch data
  const {
    data: searchData,
    error: searchError
  } = useCardSearch({
    name: searchFields.name,
    oracle: searchFields.oracle,
    type: searchFields.type || selectedCardType,
    colors: selectedColors
  });

  const { data: allSetsData } = useSets();
  const { data: allCards } = useAllCards();
  const { data: symbolData } = useCardSymbols();
  const symbols = Array.isArray(symbolData?.data) ? symbolData.data : [];

  // Get ALL cards in the current set (not paginated)
  const allCardsInSet = useMemo(() => {
    if (!allCards || !setCode) return [];

    return allCards.filter(card =>
      card.set === setCode && card.variation !== true
    ).sort((a, b) => {
      const aNum = parseInt(a.collector_number, 10) || 0;
      const bNum = parseInt(b.collector_number, 10) || 0;
      return aNum - bNum || a.name.localeCompare(b.name);
    });
  }, [allCards, setCode]);

  // Filter cards based on search or set, plus any additional filters
  const filteredCards = useMemo(() => {
    if (isSearching) return searchData?.data || [];

    let cards = allCardsInSet;

    if (selectedCardType) {
      cards = cards.filter(card =>
        card.type_line?.toLowerCase().includes(selectedCardType.toLowerCase())
      );
    }

    if (selectedColors.length > 0) {
      cards = cards.filter(card => {
        const cardColors = card.colors || [];
        return selectedColors.every(color => cardColors.includes(color));
      });
    }

    return cards;
  }, [isSearching, searchData?.data, allCardsInSet, selectedCardType, selectedColors]);

  // Paginate the filtered results
  const paginatedCards = useMemo(() => {
    return filteredCards.slice((page - 1) * 64, page * 64);
  }, [filteredCards, page]);

  // Calculate pagination info
  const totalCards = filteredCards.length;
  const totalPages = Math.ceil(totalCards / 64);
  const hasMore = page * 64 < totalCards;

  // Set info
  const allSets = Array.isArray(allSetsData?.data) ? allSetsData.data : [];
  const currentSet = allSets.find(set => set.code === setCode) || {};
  const setIcon = isSearching
    ? '/images/eyeglass.svg'
    : currentSet.icon_svg_uri || (currentSet.code ? `https://svgs.scryfall.io/sets/${currentSet.code}.svg` : null);
  const setName = isSearching
    ? 'Search Results'
    : currentSet.name || allCardsInSet[0]?.set_name || setCode?.toUpperCase() || 'Unknown Set';

  // Card color theme
  const getCardColorTheme = (card) => {
    let baseColor = '#e3b730'; // Gold default

    if (card.colors && card.colors.length > 0) {
      const colorMap = {
        W: '#F8F8F5', // White
        U: '#0E68AB', // Blue
        B: '#888888', // Black
        R: '#D3202A', // Red
        G: '#00733E'  // Green
      };
      baseColor = colorMap[card.colors[0]] || baseColor;
    }

    if (card.type_line?.includes('Land')) {
      const landColorMap = {
        'Plains': '#F8F8F5',
        'Island': '#0E68AB',
        'Swamp': '#888888',
        'Mountain': '#D3202A',
        'Forest': '#00733E'
      };

      for (const [landType, color] of Object.entries(landColorMap)) {
        if (card.type_line.includes(landType)) {
          baseColor = color;
          break;
        }
      }
    }

    return baseColor;
  };

  // Reset page when filters change
  useEffect(() => {
    setPage(1);
  }, [setCode, searchFields, selectedCardType, selectedColors]);

  // Keyboard listener for modal
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') setSelectedCard(null);
    };
    if (selectedCard) {
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedCard]);

  // Reset card face when card changes
  useEffect(() => {
    if (selectedCard) setCardFaceIndex(0);
  }, [selectedCard]);

  if (searchError) {
    return <div className="empty">Error loading search results</div>;
  }

  return (
    <>
      <div>
        <h2>
          {setIcon && <img src={setIcon} alt="" className="set-icon" />}
          {setName}{diamond}{totalCards} card(s)
          {selectedColors.length > 0 && (
            <span className="color-filter-indicator">
              {diamond}Filtered by: {selectedColors.join(', ')}
            </span>
          )}
        </h2>
      </div>

      <div className="card-grid">
        {paginatedCards.map((card) => {
          const img = card?.image_uris?.normal ||
            card.card_faces?.[0]?.image_uris?.normal ||
            `/images/mtgshield.png`;

          const layout = (card.layout ? arr_layouts[card.layout] : '');

          return (
            <img
              key={card.id}
              src={img}
              alt={card.name}
              className={`card ${layout}`}
              onClick={() => setSelectedCard(card)}
              loading="lazy"
            />
          );
        })}
      </div>

      {(totalPages > 1 || hasMore) && (
        <div className="pagination">
          {paginate(page, totalPages, hasMore).map((item, i) => {
            if (item.type === 'ellipsis') {
              return <span key={i} className="ellipsis">...</span>;
            }
            return (
              <button
                key={i}
                onClick={() => setPage(item.page)}
                className={`${item.type} ${item.isCurrent ? 'active' : ''}`}
                disabled={item.disabled || item.isCurrent}
              >
                {item.type === 'prev' && '‹ Prev'}
                {item.type === 'next' && 'Next ›'}
                {item.type === 'page' && item.page}
              </button>
            );
          })}
        </div>
      )}

      {selectedCard && (
        <div className="modal" onClick={() => setSelectedCard(null)}>
          <div
            className="modal_content"
            onClick={(e) => e.stopPropagation()}
            style={{
              '--card-tile-color': `rgba(${hexToRgb(getCardColorTheme(selectedCard)).join(', ')}, 0.09)`,
              '--card-hover-icon-color': getCardColorTheme(selectedCard),
              '--card-line-color': `rgba(${hexToRgb(darkenColor(getCardColorTheme(selectedCard), 0.2)).join(', ')}, 0.5)`,
              '--card-shine-gradient': `conic-gradient(
                from 205deg at 50% 50%,
                rgba(${hexToRgb(getCardColorTheme(selectedCard)).join(', ')}, 0) 0deg,
                rgba(${hexToRgb(getCardColorTheme(selectedCard)).join(', ')}, 0.7) 25deg,
                rgba(${hexToRgb(lightenColor(getCardColorTheme(selectedCard), 0.2)).join(', ')}, 0.18) 295deg,
                rgba(${hexToRgb(getCardColorTheme(selectedCard)).join(', ')}, 0) 360deg
              )`
            }}
          >
            <div className="modal_background">
              {Array.from({ length: 10 }).map((_, i) => (
                <div
                  key={i}
                  className="modal_tile"
                  style={{
                    animationDelay: `${-i * 2}s`,
                    ...getTilePosition(i + 1)
                  }}
                />
              ))}

              <div className="modal_line modal_line_horizontal" style={{ top: '10%' }} />
              <div className="modal_line modal_line_horizontal" style={{ top: '32.5%' }} />
              <div className="modal_line modal_line_vertical" style={{ left: '22.5%' }} />
              <div className="modal_line modal_line_vertical" style={{ left: '50%' }} />
            </div>

            <div className="modal_shine" />

            {(() => {
              const meldResultId = selectedCard.all_parts?.find(p => p.component === 'meld_result')?.id;
              const meldResult = selectedCard.layout === 'meld' && meldResultId
                ? allCards?.find(c => c.id === meldResultId)
                : null;

              const faces = selectedCard.card_faces?.length > 0
                ? selectedCard.card_faces
                : meldResult
                  ? [selectedCard, meldResult]
                  : [selectedCard];

              const face = faces[cardFaceIndex] || selectedCard;
              const image = face.image_uris?.normal || selectedCard.image_uris?.normal;
              const name = face.name || selectedCard.name;
              const set = face.set || selectedCard.set;
              const setname = face.set_name || selectedCard.set_name;
              const type = face.type_line || selectedCard.type_line;
              const keywords = face.keywords || selectedCard.keywords;
              const printed = face.printed_text || selectedCard.printed_text;
              const oracle = face.oracle_text || selectedCard.oracle_text;
              const rarity = face.rarity || selectedCard.rarity;
              const flavor = face.flavor_text || selectedCard.flavor_text;
              const artist = face.artist || selectedCard.artist;
              const price = face.prices?.usd || selectedCard.prices?.usd;

              return (
                <>
                  <img
                    src={image}
                    alt={name}
                    className='modal_image'
                    loading='lazy'
                    onClick={() => {
                      if (faces.length > 1) {
                        setCardFaceIndex((prev) => (prev + 1) % faces.length);
                      }
                    }}
                    style={{ cursor: faces.length > 1 ? 'pointer' : 'default' }}
                  />

                  <div className='modal_details'>
                    <br />
                    <h4>
                      {!isSearching && setIcon && <img src={setIcon} alt="" className="set-icon" />}
                      {name}&nbsp;{diamond}&nbsp;{type}
                    </h4>
                    <br />
                    <button
                      className='modal_link'
                      onClick={() => {
                        onSelectSet(set);
                        setSelectedCard(null);
                      }}
                    >
                      {setname}
                    </button>
                    {rarity && ` - ${rarity}`}
                    {price &&  <p>Price: ${price}</p>}

                    {printed && <p className="oracle">{renderManaSymbols(printed, symbols)}</p>}
                    {oracle && <p className="oracle">{renderManaSymbols(oracle, symbols)}</p>}

                    {flavor && <p className='flavor'>{flavor}</p>}
                    {artist && <p className='oracle'>Illustrated by {artist}</p>}

                    <strong>Keywords:</strong>{' '}
                    {keywords && keywords.length > 0
                      ? keywords.join(', ')
                      : 'No keywords available'}<p />
                    <button
                      className="modal_close_btn"
                      onClick={() => setSelectedCard(null)}
                    >
                      Close
                    </button>
                  </div>
                </>
              );
            })()}
          </div>
        </div>
      )}
    </>
  );
}

CardGallery.propTypes = {
  setCode: PropTypes.string,
  searchFields: PropTypes.shape({
    name: PropTypes.string,
    oracle: PropTypes.string,
    type: PropTypes.string,
  }),
  onSelectSet: PropTypes.func.isRequired,
  selectedCardType: PropTypes.string,
  selectedColors: PropTypes.arrayOf(PropTypes.string),
};

CardGallery.defaultProps = {
  setCode: null,
  searchFields: {},
  selectedCardType: '',
  selectedColors: [],
};

// Helper function for modal tile positioning
function getTilePosition(tileNum) {
  const positions = {
    1: { top: '0%', left: '0%', height: '10%', width: '22.5%' },
    2: { top: '0%', left: '22.5%', height: '10%', width: '27.5%' },
    3: { top: '0%', left: '50%', height: '10%', width: '27.5%' },
    4: { top: '0%', left: '77.5%', height: '10%', width: '22.5%' },
    5: { top: '10%', left: '0%', height: '22.5%', width: '22.5%' },
    6: { top: '10%', left: '22.5%', height: '22.5%', width: '27.5%' },
    7: { top: '10%', left: '50%', height: '22.5%', width: '27.5%' },
    8: { top: '10%', left: '77.5%', height: '22.5%', width: '22.5%' },
    9: { top: '32.5%', left: '50%', height: '22.5%', width: '27.5%' },
    10: { top: '32.5%', left: '77.5%', height: '22.5%', width: '22.5%' }
  };
  return positions[tileNum] || {};
}