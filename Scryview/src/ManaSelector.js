import React from 'react';

const mtgColors = [
  { code: 'W', name: 'White', url: 'https://svgs.scryfall.io/card-symbols/W.svg' },
  { code: 'U', name: 'Blue',  url: 'https://svgs.scryfall.io/card-symbols/U.svg' },
  { code: 'B', name: 'Black', url: 'https://svgs.scryfall.io/card-symbols/B.svg' },
  { code: 'R', name: 'Red',   url: 'https://svgs.scryfall.io/card-symbols/R.svg' },
  { code: 'G', name: 'Green', url: 'https://svgs.scryfall.io/card-symbols/G.svg' },
];

export default function ManaSelector({ selectedColors, setSelectedColors }) {
  const toggle = (code) => {
    const newSelected = selectedColors.includes(code)
      ? selectedColors.filter(c => c !== code)
      : [...selectedColors, code];

    setSelectedColors(newSelected);
  };

  return (
    <div style={{ display: 'flex', gap: 2 }}>
      {mtgColors.map(({ code, name, url }) => (
        <button
          key={code}
          title={name}
          onClick={() => toggle(code)}
          style={{
            width: 16,
            height: 16,
            padding: 0,
            margin: 0,
            border: selectedColors.includes(code) ? '2px solid #e3b730' : '1px solid #1e1e1e',
            background: 'none',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <img src={url} alt={code} style={{ width: 12, height: 12 }} />
        </button>
      ))}
    </div>
  );
}