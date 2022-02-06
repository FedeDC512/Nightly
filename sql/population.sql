DELETE FROM Utenti;

INSERT INTO Utenti(Username, Nome, Cognome, Email, Password) VALUES 
("alwe", "Daniele", "Nicosia", "danynic20@gmail.com", SHA2("dany", 256)),
("gioza", "Giorgio", "Zangara", "giozangara@yahoo.com", SHA2("zang", 256)),
("fededc", "Federico", "Agnello", "fedearceus@virgilio.it", SHA2("fededc", 256)),
("sabrim", "Sabrina", "Mantaci", "sabrina.mantaci@unipa.it", SHA2("sabrify", 256));

-- Cercare brani nel portale
SELECT * FROM Brani WHERE Titolo LIKE '%{$testoRicerca}%';

-- Estendere i like a tutti i brani dell'album :
-- dentro ad un loop per ogni brano presente in BraniAlbum in base all'id dell'album
-- usare la query di "Mettere like ad un brano"

-- Mettere like ad un album
INSERT INTO PiaceAlbum(Album, Utente) VALUES({$idAlbum}, {$nomeUtente});

-- Estendere i like a tutti i brani della playlist :
-- dentro ad un loop per ogni brano presente in BraniPlaylist in base all'id della playlist
-- usare la query di "Mettere like ad un brano"

-- Mettere like ad una playlist
INSERT INTO PiacePlaylist(Playlist, Utente) VALUES({$idPlaylist}, {$nomeUtente});

-- Mettere like ad un brano
INSERT INTO PiaceBrano(Brano, Utente) VALUES({$idBrano}, {$nomeUtente});

-- Mettere il brano in una playlist
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES ({$idBrano}, {$idPlaylist});

-- Inserimento di un nuovo brano
INSERT INTO Brani(Titolo, Durata, DataPubblicazione) VALUES ({$titoloBrano}, {$durataBrano}, {$dataBrano});
INSERT INTO BraniArtista(Brano, Artista) VALUES({$idBrano}, {$idArtista});

-- Inserimento di un nuovo album
INSERT INTO Album(Titolo, Anno) VALUES ({$titoloAlbum}, {$annoAlbum});
INSERT INTO AlbumArtista(Album, Artista) VALUES({$idAlbum}, {$idArtista});
-- Inserimento dei brani nell'album
INSERT INTO BraniAlbum(Brano, Album) VALUES({$idBrano1}, {$idAlbum});
INSERT INTO BraniAlbum(Brano, Album) VALUES({$idBrano2}, {$idAlbum});
INSERT INTO BraniAlbum(Brano, Album) VALUES({$idBrano3}, {$idAlbum});
INSERT INTO BraniAlbum(Brano, Album) VALUES({$idBrano4}, {$idAlbum});
INSERT INTO BraniAlbum(Brano, Album) VALUES({$idBrano5}, {$idAlbum});

-- Inserimento di una nuova playlist
INSERT INTO Playlist(Titolo, Manuale) VALUES ({$titoloPlaylist}, true);
INSERT INTO PlaylistInLibreria(Libreria, Playlist) VALUES({$idLibreriaUtente}, {$idPlaylist});
-- Inserimento dei brani nella playlist
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano1}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano2}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano3}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano4}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano5}, {$idPlaylist});

-- Visualizzare nomi dei follower di un utente
SELECT Follower FROM UtentiSeguiti WHERE Utente = {$nomeUtente};
-- Visualizzare numero follower di un utente
SELECT COUNT(*) AS numeroFollower FROM UtentiSeguiti WHERE Utente = {$nomeUtente};

-- Visualizzare il numero di like messi da un utente nell'ultimo mese
SELECT COUNT(*) as numeroLike FROM PiaceBrano WHERE Utente = {$nomeUtente} AND (
    DataInserimento BETWEEN CONCAT(YEAR(CURRENT_DATE()) + '-' + MONTH(CURRENT_DATE()) + '-01') 
    AND CONCAT(YEAR(CURRENT_DATE()) + '-' + MONTH(CURRENT_DATE()) + '-' + LAST_DAY(CURRENT_DATE()))
);

-- Visualizzare il numero di ascolti messi da un utente nell'ultimo mese
SELECT COUNT(*) as numeroAscolti FROM AscoltiTotali WHERE Utente = {$nomeUtente} 
AND Mese = CONCAT(YEAR(CURRENT_DATE()) + '-' + MONTH(CURRENT_DATE()))

-- Visualizzare nomi dei follower di un artista
SELECT Follower FROM ArtistiSeguiti WHERE Artista = {$idArtista};
-- Visualizzare numero follower di un artista
SELECT COUNT(*) AS numeroFollower FROM ArtistiSeguiti WHERE Artista = {$idArtista};

-- Visualizzare i brani che piacciono ad un utente
SELECT Titolo FROM Brani b JOIN PiaceBrano pb ON b.BranoID = pb.Brano WHERE pb.Utente = {$nomeUtente};

-- Attribuire ogni settimana il compenso a ciascun artista in base ad ascolti e mi piace
DECLARE ga INT;
SET ga = SELECT Compenso FROM Compensi WHERE Categoria = "ascolto";

DECLARE gmp INT;
SET gmp = SELECT Compenso FROM Compensi WHERE Categoria = "mi piace";

DECLARE sa INT;
SET sa = SELECT SUM(Ascolti) FROM AscoltiTotali WHERE Brano = (
    SELECT b.BranoID FROM Brani b JOIN BraniArtista ba ON ba.Brano = b.BranoID
    WHERE ba.Artista = {$idArtista}
);

DECLARE smp INT;
SET smp = SELECT COUNT(*) FROM PiaceBrano WHERE Brano = (
    SELECT b.BranoID FROM Brani b JOIN BraniArtista ba ON ba.Brano = b.BranoID
    WHERE ba.Artista = {$idArtista}
);

INSERT INTO Guadagni(Artista, Guadagno) VALUES({$idArtista}, (ga * sa) + (gmp * smp));

-- Fare ogni giorno una classifica dei generi più ascoltati dall'utente
SELECT g.Tipo FROM Generi g JOIN GeneriBrano gb ON g.GenereID = gb.Genere 
JOIN AscoltiTotali ast ON gb.Brano = ast.Brano 
WHERE ast.Utente = {$nomeUtente} ORDER BY Ascolti;

-- Creare una playlist intelligente che contenga i brani con più ascolti dei generi ascoltati dall'utente
CREATE VIEW generiAscoltati AS SELECT GenereID, Brano, Utente FROM GeneriBrano gb
JOIN AscoltiTotali ast ON gb.Brano = ast.Brano ORDER BY Ascolti;

SELECT Brano FROM Generi g JOIN generiAscoltati ga ON g.GenereID = ga.GenereID
JOIN PiaceBrano pb ON ga.Brano = pb.Brano WHERE ga.Utente = {$nomeUtente} LIMIT 15;

INSERT INTO Playlist(Titolo, Manuale) VALUES ("Playlist intelligente", false);
INSERT INTO PlaylistInLibreria(Libreria, Playlist) VALUES({$idLibreriaUtente}, {$idPlaylist});
-- Inserimento dei brani nella playlist
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano1}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano2}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano3}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano4}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano5}, {$idPlaylist});
-- e così via...

-- Creazione di una playlist giornaliera, settimanale, mensile e annuale per ogni utente
CREATE VIEW braniPiaciuti AS SELECT Brano, COUNT(*) AS numeroLike FROM PiaceBrano GROUP BY Brano;

SELECT Brano FROM braniPiaciuti ORDER BY numeroLike LIMIT 15;

-- Per ogni utente :
INSERT INTO Playlist(Titolo, Manuale) VALUES ("Playlist automatica", false);
INSERT INTO PlaylistInLibreria(Libreria, Playlist) VALUES({$idLibreriaUtente}, {$idPlaylist});
-- Inserimento dei brani nella playlist :
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano1}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano2}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano3}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano4}, {$idPlaylist});
INSERT INTO BraniPlaylist(Brano, Playlist) VALUES({$idBrano5}, {$idPlaylist});
-- e così via...