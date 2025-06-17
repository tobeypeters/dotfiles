import React, { useEffect, useState } from "react";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import "./App.css";

const App = () => {
  const [sets, setSets] = useState([]);
  const [setTypes, setSetTypes] = useState([]);
  const [setType, setSetType] = useState(localStorage.getItem("selectedType") || "all");
  const [setCode, setSetCode] = useState(localStorage.getItem("selectedSet") || "");
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
    const fetchSets = async () => {
      try {
        const res = await fetch("https://api.scryfall.com/sets");
        if (!res.ok) throw new Error("Failed to fetch sets.");
        const data = await res.json();
        const relevantSets = data.data
          .filter((s) => s.set_type !== "token" && s.set_type !== "memorabilia" && s.released_at)
          .sort((a, b) => new Date(a.released_at) - new Date(b.released_at));

        const types = Array.from(new Set(relevantSets.map((s) => s.set_type))).sort();
        setSetTypes(types);
        setSets(relevantSets);

        const defaultSet = relevantSets.find(s => s.set_type === setType)?.code || relevantSets[0]?.code || "";
        setSetCode(defaultSet);
        localStorage.setItem("selectedSet", defaultSet);
      } catch (err) {
        console.error(err);
        toast.error("Failed to fetch MTG sets.");
      }
    };
    fetchSets();
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
      ? `https://api.scryfall.com/cards/search?q=${encodeURIComponent(search)}&unique=prints`
      : `https://api.scryfall.com/cards/search?q=e%3A${setCode}`;

    const fetchCards = async () => {
      try {
        const res = await fetch(`${baseQuery}&page=${page}`);
        if (!res.ok) throw new Error("Failed to fetch cards.");
        const data = await res.json();
        setCards(data.data || []);
        setTotalCards(data.total_cards || data.total || 0);
      } catch (err) {
        console.error(err);
        toast.error("Failed to fetch cards. Please check your connection.");
      }
    };
    fetchCards();
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

  const isFavorite = (card) =>
    favorites.some((c) => c.id === card.id);

  const filteredSets = setType === "all" ? sets : sets.filter((s) => s.set_type === setType);
  const totalPages = Math.ceil(totalCards / cards.length || 1);
  const maxVisiblePages = 10;
  const half = Math.floor(maxVisiblePages / 2);
  const startPage = Math.max(1, page - half);
  const endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);

  return (
    <div className="app">
      <ToastContainer />

      <div className="header">
        <h1>Magic: The Gathering Cards</h1>
        <img src="/images/mtgshield.png" alt="MTG Shield" className="corner-image" />
      </div>

      <form
        className="controls"
        onSubmit={(e) => {
          e.preventDefault();
          setPage(1);
        }}
      >
        <select
          value={setType}
          onChange={(e) => {
            setSetType(e.target.value);
            setSearch(""); // clear search on type change
          }}
        >
          <option value="all">All Set Types</option>
          {setTypes.map((type) => (
            <option key={type} value={type}>
              {type.replace(/_/g, " ").replace(/\b\w/g, (l) => l.toUpperCase())}
            </option>
          ))}
        </select>

        <select
          value={setCode}
          onChange={(e) => {
            setSetCode(e.target.value);
            setPage(1);
            setSearch(""); // clear search on set change
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
            setSetType("all"); // reset type to all on manual search
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
            {search && search.length > 0 && <p style={{ fontSize: '0.85rem', color: '#ccc' }}>{card.set_name}</p>}
          </div>
        ))}
      </div>

      {totalPages > 1 && (
        <div className="pagination">
          {startPage > 1 && (
            <button onClick={() => setPage(1)}>« First</button>
          )}
          {Array.from({ length: endPage - startPage + 1 }, (_, i) => startPage + i)
            .map((p) => (
              <button
                key={p}
                onClick={() => setPage(p)}
                disabled={p === page}
              >
                {p}
              </button>
            ))}
          {endPage < totalPages && (
            <button onClick={() => setPage(totalPages)}>Last »</button>
          )}
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
