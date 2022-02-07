-- Creazione del database

DROP DATABASE IF EXISTS nightly;
CREATE DATABASE nightly;
USE nightly;

-- Creazione dei trigger

-- Trigger che si attiva quando viene ascoltata un brano da un utente
CREATE TRIGGER TriggerAscolti AFTER INSERT ON AscoltoAdesso BEGIN
    IF (EXISTS (SELECT Mese FROM AscoltiTotali WHERE Mese = CURRENT_DATE())) THEN 
        UPDATE AscoltiTotali SET new.Ascolti = new.Ascolti + 1 
        WHERE Brano = new.Brano AND Utente = new.Utente
    ELSE
        INSERT INTO AscoltiTotali(Brano, Utente, Ascolti, Mese)
        VALUES (new.Brano, new.Utente, 1, CURRENT_DATE());
    END IF;
END

-- Trigger che si attiva quando viene messo like ad un album
CREATE TRIGGER TriggerPiaceAlbum AFTER INSERT ON PiaceAlbum BEGIN
	SELECT Brano FROM BraniAlbum WHERE Album = new.Album;
	-- PER OGNI BRANO TROVATO NEL SELECT PRECEDENTE, FARE :
	INSERT INTO PiaceBrano(Brano, Utente) VALUES({$BranoID}, new.Utente);
END

-- Trigger che si attiva quando viene messo like ad una playlist
CREATE TRIGGER TriggerPiacePlaylist AFTER INSERT ON PiacePlaylist BEGIN
	DECLARE lu INT;
	SET lu = SELECT LibreriaID FROM Librerie WHERE Possessore = new.Utente;
	INSERT INTO PlaylistInLibreria(Libreria, Playlist) VALUES(lu, new.Playlist);
	
	SELECT Brano FROM BraniPlaylist WHERE Playlist = new.Playlist;
	-- PER OGNI BRANO TROVATO NEL SELECT PRECEDENTE, FARE :
	INSERT INTO PiaceBrano(Brano, Utente) VALUES({$BranoID}, new.Utente);
END

-- Creazione delle tabelle delle entità

CREATE TABLE Utenti (
	Username VARCHAR(30) PRIMARY KEY, 
	Nome VARCHAR(100) NOT NULL,
	Cognome VARCHAR(100) NOT NULL,
	FotoProfilo TEXT DEFAULT 'Non specificata',
	Email VARCHAR(200) NOT NULL,
	Password VARCHAR(64) NOT NULL,
	DataIscrizione DATE DEFAULT CURRENT_DATE()
);

CREATE TABLE Librerie (
	LibreriaID INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	Sfondo TEXT DEFAULT 'Non specificata',
	Possessore VARCHAR(30) REFERENCES Utenti(Username) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Etichette (
	Nome VARCHAR(250) PRIMARY KEY,
	Via VARCHAR(100) DEFAULT 'Non specificata',
	Citta VARCHAR(60) DEFAULT 'Non specificata',
	AnnoFondazione YEAR NOT NULL
);

CREATE TABLE Generi (
	GenereID INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	Tipo VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE Brani (
	BranoID INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, 
	Titolo VARCHAR(250) NOT NULL, 
	Durata MEDIUMINT UNSIGNED NOT NULL, 
	DataPubblicazione DATE NOT NULL,
	Copertina TEXT DEFAULT 'Non specificata'
);

CREATE TABLE Album (
	AlbumID INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,  
	Titolo VARCHAR(250) NOT NULL,  
	Anno YEAR NOT NULL, 
	Copertina TEXT DEFAULT 'Non specificata'
);

CREATE TABLE Artisti (
	ArtistaID INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	NomeInArte VARCHAR(200) NOT NULL, 
	Descrizione TEXT DEFAULT 'Non presente',
	NomeCompleto VARCHAR(250) DEFAULT 'Sconosciuto',
	Etichetta VARCHAR(250) REFERENCES Etichette(Nome) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Playlist (
	PlaylistID INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	Titolo VARCHAR(250) NOT NULL,
	DataCreazione DATE DEFAULT CURRENT_DATE(),
	Manuale BOOLEAN NOT NULL
);

CREATE TABLE Compensi (
	Categoria VARCHAR(50) UNIQUE NOT NULL,
	Compenso FLOAT NOT NULL
);

CREATE TABLE Guadagni (
	Artista INT UNSIGNED REFERENCES Artisti(ArtistaID) ON DELETE CASCADE ON UPDATE CASCADE,
	Guadagno FLOAT NOT NULL, 
	Settimana DATE NOT NULL
);

-- Creazione delle tabelle delle relazioni

CREATE TABLE ComposizioneBand (
	Band INT UNSIGNED REFERENCES Artisti(ArtistaID) ON DELETE CASCADE ON UPDATE CASCADE,
	Artista INT UNSIGNED REFERENCES Artisti(ArtistaID) ON DELETE CASCADE ON UPDATE CASCADE,
	Ruolo VARCHAR(100) NOT NULL,
	UNIQUE KEY (Band, Artista, Ruolo)
);

CREATE TABLE UtentiSeguiti (
	Utente VARCHAR(30) REFERENCES Utenti(Username) ON DELETE CASCADE ON UPDATE CASCADE,
	Follower VARCHAR(30) REFERENCES Utenti(Username) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Utente, Follower)
);

CREATE TABLE ArtistiSeguiti (
	Artista INT UNSIGNED REFERENCES Artisti(ArtistaID) ON DELETE CASCADE ON UPDATE CASCADE,
	Follower VARCHAR(30) REFERENCES Utenti(Username) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Artista, Follower)
);

CREATE TABLE BraniArtista (
	Brano INT UNSIGNED REFERENCES Brani(BranoID) ON DELETE CASCADE ON UPDATE CASCADE,
	Artista INT UNSIGNED REFERENCES Artisti(ArtistaID) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Brano, Artista)
);

CREATE TABLE BraniAlbum (
	Brano INT UNSIGNED REFERENCES Brani(BranoID) ON DELETE CASCADE ON UPDATE CASCADE,
	Album INT UNSIGNED REFERENCES Album(AlbumID) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Brano, Album)
);

CREATE TABLE BraniPlaylist (
	Brano INT UNSIGNED REFERENCES Brani(BranoID) ON DELETE CASCADE ON UPDATE CASCADE,
	Playlist INT UNSIGNED REFERENCES Playlist(PlaylistID) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Brano, Playlist)
);

CREATE TABLE AlbumArtista (
	Album INT UNSIGNED REFERENCES Album(AlbumID) ON DELETE CASCADE ON UPDATE CASCADE,
	Artista INT UNSIGNED REFERENCES Artisti(ArtistaID) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Album, Artista)
);

CREATE TABLE PlaylistInLibreria (
	Libreria INT UNSIGNED REFERENCES Librerie(LibreriaID) ON DELETE CASCADE ON UPDATE CASCADE,
	Playlist INT UNSIGNED REFERENCES Playlist(PlaylistID) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Libreria, Playlist)
);

CREATE TABLE PlaylistUtente (
	Playlist INT UNSIGNED REFERENCES Playlist(PlaylistID) ON DELETE CASCADE ON UPDATE CASCADE,
	Utente VARCHAR(30) REFERENCES Utenti(Username) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Playlist, Utente)
);

CREATE TABLE GeneriBrano (
	Brano INT UNSIGNED REFERENCES Brani(BranoID) ON DELETE CASCADE ON UPDATE CASCADE,
	Genere INT UNSIGNED REFERENCES Generi(GenereID) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Brano, Genere)
);

CREATE TABLE GeneriAlbum (
	Album INT UNSIGNED REFERENCES Album(AlbumID) ON DELETE CASCADE ON UPDATE CASCADE,
	Genere INT UNSIGNED REFERENCES Generi(GenereID) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Album, Genere)
);

CREATE TABLE GeneriArtista (
	Artista INT UNSIGNED REFERENCES Artista(ArtistaID) ON DELETE CASCADE ON UPDATE CASCADE,
	Genere INT UNSIGNED REFERENCES Generi(GenereID) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Artista, Genere)
);

CREATE TABLE PiaceBrano (
	Brano INT UNSIGNED REFERENCES Brani(BranoID) ON DELETE CASCADE ON UPDATE CASCADE,
	Utente VARCHAR(30) REFERENCES Utenti(Username) ON DELETE CASCADE ON UPDATE CASCADE,
	DataInserimento DATE DEFAULT CURRENT_DATE(),
	UNIQUE KEY (Brano, Utente)
);

CREATE TABLE PiaceAlbum (
	Album INT UNSIGNED REFERENCES Album(AlbumID) ON DELETE CASCADE ON UPDATE CASCADE,
	Utente VARCHAR(30) REFERENCES Utenti(Username) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Album, Utente)
);

CREATE TABLE PiacePlaylist (
	Playlist INT UNSIGNED REFERENCES Playlist(PlaylistID) ON DELETE CASCADE ON UPDATE CASCADE,
	Utente VARCHAR(30) REFERENCES Utenti(Username) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Playlist, Utente)
);

CREATE TABLE AscoltoAdesso (
	Brano INT UNSIGNED REFERENCES Brani(BranoID) ON DELETE CASCADE ON UPDATE CASCADE,
	Utente VARCHAR(30) REFERENCES Utenti(Username) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE KEY (Brano, Utente)
);

CREATE TABLE AscoltiTotali (
	Brano INT UNSIGNED REFERENCES Brani(BranoID) ON DELETE CASCADE ON UPDATE CASCADE,
	Utente VARCHAR(30) REFERENCES Utenti(Username) ON DELETE CASCADE ON UPDATE CASCADE,
	Ascolti INT UNSIGNED DEFAULT 0,
	Mese DATE DEFAULT CONCAT(YEAR(CURRENT_DATE()) + '-' + MONTH(CURRENT_DATE())),
	UNIQUE KEY (Brano, Utente, Mese)
);