import { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useSetTypes, useCardTypes } from '../Api';
import { DEBUG_CONFIG, DebugPanel } from '../DebugPanel';
import ManaSelector from '../ManaSelector';

export const Home = ({
  sets = [],
  onSelect,
  selectedSet,
  selectedType,
  onTypeChange,
  selectedCardType,
  onCardTypeChange,
  searchFields = { name: '', oracle: '' },
  updateSearch,
  selectedColors = [],
  setSelectedColors,
}) => {
  // All hooks must be called unconditionally at the top
  const {
    data: setTypesData,
    isLoading: isLoadingTypes,
    error: typesError
  } = useSetTypes();

  const {
    data: cardTypesData,
    isLoading: isLoadingCardTypes,
    error: cardTypesError
  } = useCardTypes(sets);

  const setTypes = setTypesData?.data || [];
  const cardTypes = cardTypesData?.data || [];

  // Auto-select first set when type is "All Set Types" and no set is selected
  useEffect(() => {
    if (selectedType === "" && sets.length > 0 && !selectedSet) {
      onSelect(sets[0].code);
    }
  }, [selectedType, sets, selectedSet, onSelect]);

  if (typesError || cardTypesError) {
    return (
      <div className="error-message">
        Error loading filter options: {(typesError || cardTypesError).message}
        <button onClick={() => window.location.reload()}>Retry</button>
      </div>
    );
  }

  return (
    <div className="filter-controls">
      {/* Set Type Dropdown */}
      <div className="filter-group">
        <select
          id="set-type"
          onChange={(e) => {
            onTypeChange(e.target.value);
            onCardTypeChange('');
            setSelectedColors([]);
          }}
          value={selectedType || ""}
          className="type-dropdown"
          disabled={isLoadingTypes || !setTypes.length}
        >
          <option value="">All Set Types</option>
          {setTypes.map((type) => (
            <option key={type.value} value={type.value}>
              {type.label}
            </option>
          ))}
        </select>
        {isLoadingTypes && <span className="loading-indicator">Loading types...</span>}
      </div>

      {/* Set Dropdown */}
      <div className="filter-group">
        <select
          id="set-select"
          onChange={(e) => {
            onSelect(e.target.value);
            onCardTypeChange('');
            setSelectedColors([]);
          }}
          value={selectedSet || (sets[0]?.code || "")}
          className="set-dropdown"
          disabled={!sets.length}
        >
          {sets.map((set) => (
            <option key={set.code} value={set.code}>
              {set.name} ({set.released_at?.substring(0, 4) || 'N/A'})
            </option>
          ))}
        </select>
      </div>

      {/* Card Type Dropdown */}
      <div className="filter-group">
        <select
          id="card-type"
          onChange={(e) => {
            onCardTypeChange(e.target.value);
            setSelectedColors([]);
          }}
          value={selectedCardType || ""}
          className="type-dropdown"
          disabled={isLoadingCardTypes || !cardTypes.length}
        >
          <option value="">All Card Types</option>
          {cardTypes.map((type) => (
            <option key={type.value} value={type.value}>
              {type.label}
            </option>
          ))}
        </select>
        {isLoadingCardTypes && <span className="loading-indicator">Loading card types...</span>}
      </div>

      {/* Search Inputs */}
      <div className="filter-group">
        <input
          id="card-name"
          type="text"
          placeholder="Search by card name"
          value={searchFields.name}
          onChange={(e) => updateSearch(e.target.value, searchFields.oracle)}
          className="search-box"
        />
      </div>

      <div className="filter-group">
        <input
          id="oracle-text"
          type="text"
          placeholder="Search by oracle text"
          value={searchFields.oracle}
          onChange={(e) => updateSearch(searchFields.name, e.target.value)}
          className="search-box"
        />
      </div>

      {/* Mana Color Selector */}
      <div className="filter-group">
        <ManaSelector
          selectedColors={selectedColors}
          setSelectedColors={setSelectedColors}
        />
      </div>

      {DEBUG_CONFIG.SHOW_DEBUG && (
        <DebugPanel
          title="Home.js - Debug info"
          position="top-right"
          data={{
            'Sets': sets.length,
            'Set Types': setTypes.length,
            'Card Types': cardTypes.length,
            'Current Filters': {
              'Set Type': selectedType || 'None',
              'Set': selectedSet || 'None',
              'Card Type': selectedCardType || 'None',
              'Selected Colors': selectedColors.length > 0 ? selectedColors.join(', ') : 'None',
              'Name Search': searchFields.name || 'None',
              'Oracle Search': searchFields.oracle || 'None'
            }
          }}
        />
      )}
    </div>
  );
};

Home.propTypes = {
  sets: PropTypes.arrayOf(
    PropTypes.shape({
      code: PropTypes.string.isRequired,
      name: PropTypes.string.isRequired,
      released_at: PropTypes.string,
      set_type: PropTypes.string,
      icon_svg_uri: PropTypes.string
    })
  ).isRequired,
  onSelect: PropTypes.func.isRequired,
  selectedSet: PropTypes.string,
  selectedType: PropTypes.string,
  selectedCardType: PropTypes.string,
  onTypeChange: PropTypes.func.isRequired,
  onCardTypeChange: PropTypes.func.isRequired,
  searchFields: PropTypes.shape({
    name: PropTypes.string,
    oracle: PropTypes.string,
  }),
  updateSearch: PropTypes.func.isRequired,
  selectedColors: PropTypes.arrayOf(PropTypes.string),
  setSelectedColors: PropTypes.func,
};

Home.defaultProps = {
  sets: [],
  searchFields: { name: '', oracle: '' },
  selectedCardType: '',
  selectedColors: [],
  setSelectedColors: () => {},
};