import React, { useEffect, useState } from "react";
import "./App.css";

const App = () => {
  const [sets, setSets] = useState([]);
  const [setCode, setSetCode] = useState(localStorage.getItem("selectedSet") || "");
  const [setType, setSetType] = useState(localStorage.getItem("selectedType") || "all");
  const [cards, setCards] = useState([]);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [totalCards, setTotalCards] = useState(0);
  const [selectedCard, setSelectedCard] = useState(null);
  const [favorites, setFavorites] = useState(() => {
    const saved = localStorage.getItem("favorites");
    return saved ? JSON.parse(saved) : [];
  });

  useEffect(() => {
    fetch("https://api.scryfall.com/sets")
      .then((res) => res.json())
      .then((data) => {
        const relevantSets = data.data
          .filter((s) => s.set_type !== "token" && s.set_type !== "memorabilia" && s.released_at)
          .sort((a, b) => new Date(a.released_at) - new Date(b.released_at));
        setSets(relevantSets);

        const defaultSet = relevantSets.find((s) => s.set_type === setType)?.code || relevantSets[0]?.code || "";
        setSetCode(defaultSet);
        localStorage.setItem("selectedSet", defaultSet);
      });
  }, [setType]);

  useEffect(() => {
    localStorage.setItem("selectedType", setType);
    const filtered = setType === "all" ? sets : sets.filter((s) => s.set_type === setType);

    if (filtered.length > 0) {
      const firstSet = filtered[0].code;
      setSetCode(firstSet);
      localStorage.setItem("selectedSet", firstSet);
      setPage(1);
      setSearch("");
    }
  }, [setType, sets]);

  useEffect(() => {
    if (!setCode && !search) return;

    const baseQuery = search
      ? `https://api.scryfall.com/cards/search?q=${encodeURIComponent(search)}`
      : `https://api.scryfall.com/cards/search?q=e%3A${setCode}`;

    fetch(`${baseQuery}&page=${page}`)
      .then((res) => res.json())
      .then((data) => {
        setCards(data.data || []);
        setTotalCards(data.total_cards || data.total || 0);
      });
  }, [setCode, page, search]);

  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === "Escape") setSelectedCard(null);
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, [page]);

  const toggleFavorite = (card) => {
    const exists = favorites.find((c) => c.id === card.id);
    const updated = exists
      ? favorites.filter((c) => c.id !== card.id)
      : [...favorites, card];

    setFavorites(updated);
    localStorage.setItem("favorites", JSON.stringify(updated));
  };

  const isFavorite = (card) => favorites.some((c) => c.id === card.id);
  const filteredSets = setType === "all" ? sets : sets.filter((s) => s.set_type === setType);
  const totalPages = Math.ceil(totalCards / (cards.length || 1));

  return (
    <div className="app">
      <div className="header">
        <h1>Magic: The Gathering Cards</h1>
        <img src="/images/mtgshield.png" alt="MTG Shield" className="corner-image" />
      </div>

      <form className="controls" onSubmit={(e) => e.preventDefault()}>
        <select value={setType} onChange={(e) => setSetType(e.target.value)}>
          <option value="all">All Set Types</option>
          <option value="core">Core</option>
          <option value="expansion">Expansion</option>
          <option value="masters">Masters</option>
          <option value="draft_innovation">Draft Innovation</option>
          <option value="funny">Un-sets</option>
          <option value="commander">Commander</option>
          <option value="starter">Starter</option>
        </select>

        <select
          value={setCode}
          onChange={(e) => {
            setSetCode(e.target.value);
            setPage(1);
          }}
        >
          {filteredSets.map((s) => (
            <option key={s.code} value={s.code}>
              {s.name} ({s.code.toUpperCase()}) – {new Date(s.released_at).getFullYear()}
            </option>
          ))}
        </select>

        <input
          type="text"
          placeholder="Search cards..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
        />
        <button type="submit">Search</button>
      </form>

      <div className="card-grid">
        {cards.map((card) => (
          <div className="card" key={card.id}>
            {card.image_uris?.normal ? (
              <img
                src={card.image_uris.normal}
                alt={card.name}
                onClick={() => setSelectedCard(card)}
              />
            ) : (
              <p>No image</p>
            )}
            <p>{card.name}</p>
          </div>
        ))}
      </div>

      {totalPages > 1 && (
        <div className="pagination">
          {Array.from({ length: totalPages }, (_, i) => i + 1)
            .filter((p) => Math.abs(p - page) <= 2 || p === 1 || p === totalPages)
            .map((p) => (
              <button
                key={p}
                onClick={() => setPage(p)}
                style={{ fontWeight: p === page ? "bold" : "normal" }}
              >
                {p}
              </button>
            ))}
        </div>
      )}

      {selectedCard && (
        <div className="modal" onClick={() => setSelectedCard(null)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-left">
              {selectedCard.image_uris?.normal && (
                <img
                  src={selectedCard.image_uris.normal}
                  alt={selectedCard.name}
                  style={{ backgroundColor: "#1e1e1e" }}
                />
              )}
            </div>
            <div className="modal-right">
              <h2>{selectedCard.name}</h2>
              <p>{selectedCard.type_line}</p>
              <p>{selectedCard.oracle_text}</p>
              {selectedCard.prices?.usd && (
                <p><strong>Price:</strong> ${selectedCard.prices.usd}</p>
              )}
              <div className="modal-buttons">
                <button onClick={() => setSelectedCard(null)}>Close</button>
                <button onClick={() => toggleFavorite(selectedCard)}>
                  {isFavorite(selectedCard) ? "★ Remove Favorite" : "☆ Add to Favorites"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {favorites.length > 0 && (
        <div className="favorites">
          <h2>★ Favorites</h2>
          <div className="card-grid">
            {favorites.map((card) => (
              <div className="card" key={card.id}>
                {card.image_uris?.normal ? (
                  <img
                    src={card.image_uris.normal}
                    alt={card.name}
                    onClick={() => setSelectedCard(card)}
                  />
                ) : (
                  <p>No image</p>
                )}
                <p>{card.name}</p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default App;
