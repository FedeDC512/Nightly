const { doQuery } = require('./functions')
const MusicBrainzApi = require('musicbrainz-api').MusicBrainzApi

const mbApi = new MusicBrainzApi({
    appName: 'nightly',
    appVersion: '1.0.0',
    appContactInfo: 'http://localhost:8000/home'
})

const labelsList = [ "Sony Music", "Spinnin' Records", "Island Record", "Warner Music Group", "Republic Records" ]

const artistsList = [
    { name: "Imagine Dragons", country: "US", type: "Group" },
    { name: "Ariete", country: "IT", type: "Person" },
    { name: "Ultimo", country: "IT", type: "Person" },
    { name: "Gazzelle", country: "IT", type: "Person" },
    { name: "Katy Perry", country: "US", type: "Person" },
    { name: "MIKA", country: "GB", type: "Person" },
    { name: "Maroon 5", country: "US", type: "Group" },
    { name: "Ariana Grande", country: "US", type: "Person" },
    { name: "Franco Battiato", country: "IT", type: "Person" },
    { name: "Beatles", country: "GB", type: "Group" },
    { name: "Coldplay", country: "GB", type: "Group" },
    { name: "Tiziano Ferro", country: "IT", type: "Person" },
    { name: "Ligabue", country: "IT", type: "Person" },
    { name: "Zucchero", country: "IT", type: "Person" },
    { name: "Lucio Dalla", country: "IT", type: "Person" },
    { name: "Gianna Nannini", country: "IT", type: "Person" },
    { name: "Mahmood", country: "IT", type: "Person" },
    { name: "Loredana Bertè", country: "IT", type: "Person" },
    { name: "Maneskin", country: "IT", type: "Group" },
    { name: "Orietta Berti", country: "IT", type: "Person" },
    { name: "Fedez", country: "IT", type: "Person" },
    { name: "Arisa", country: "IT", type: "Person" },
    { name: "Ermal Meta", country: "IT", type: "Person" },
    { name: "Sfera Ebbasta", country: "IT", type: "Person" },
    { name: "Al Bano", country: "IT", type: "Person" },
    { name: "Noemi", country: "IT", type: "Person" },
    { name: "Jovanotti", country: "IT", type: "Person" },
    { name: "Taylor Swift", country: "US", type: "Person" },
    { name: "Lady Gaga", country: "US", type: "Person" },
    { name: "Queen", country: "GB", type: "Group" },
    { name: "Rolling Stones", country: "GB", type: "Group" }
]

const labelsInfos = []
const artistsInfos = []

async function populate() {
    console.time("Fetched in")
    for await (const l of labelsList) {
        let result = await mbApi.search('label', { query: { name: l }, limit: 3 })
        let label = result.labels[0]
        if (label == undefined) continue
        labelsInfos.push({
            name: label.name,
            beginYear: label["life-span"].begin ? label["life-span"].begin : 1900
        })
    }
    for await (const a of artistsList) {
        let result = await mbApi.searchArtist({ 
            query: `${a.name} AND ((type:${a.type} OR country:${a.country}) OR (type:${a.type} AND country:${a.country}))`, 
            limit: 3 
        })
        let artist = result.artists[0]
        if (artist == undefined) continue
        let fullName = "Sconosciuto"
        if (artist.aliases != undefined) {
            let legalName = artist.aliases.find(o => o.type == "Legal name")
            if (artist.aliases.length == 1) fullName = artist.aliases[0].name
            else fullName = legalName ? legalName.name : "Sconosciuto"
        }
        artistsInfos.push({
            artistId: artist.id,
            alias: artist.name,
            fullName: fullName,
            description: artist.disambiguation ? artist.disambiguation : "Non presente",
            genres: artist.tags ? artist.tags.map(g => g.name) : [],
            albums: []
        })
    }
    for await (const a of artistsInfos) {
        let result = await mbApi.search('release', { query: { arid: a.artistId }, limit: 10 })
        result.releases.forEach(r => {
            if (a.albums.find(o => o.title.toLowerCase() == r.title.toLowerCase()) == undefined) {
                a.albums.push({
                    albumId: r.id,
                    title: r.title,
                    nTracks: r["track-count"],
                    releaseYear: r.date ? Number(r.date.split("-")[0]) : 1900,
                    genres: r.tags ? r.tags.map(g => g.name) : [],
                    tracks: []
                })
            }
        })
    }
    for await (const ai of artistsInfos) {
        for await (const a of ai.albums) {
            let result = await mbApi.search('recording', { query: { reid: a.albumId } })
            result.recordings.forEach(t => {
                if (a.tracks.find(o => o.title.toLowerCase() == t.title.toLowerCase()) == undefined
                    && t.length != 0) {
                    a.tracks.push({
                        branoId: t.id,
                        title: t.title,
                        length: t.length,
                        genres: t.tags ? t.tags.map(g => g.name) : [],
                        releaseDate: t['first-release-date']
                    })
                }
            })
        }
    }
    console.timeEnd("Fetched in")
}

populate().then(() => {
    console.log("Start inserting into database in 10 seconds...")
    setTimeout(async () => {
        console.time("Inserted in")
        for (const li of labelsInfos) {
            await doQuery('INSERT INTO Etichette SET ?', {
                Nome: li.name,
                AnnoFondazione: li.beginYear
            })
        }
        let lastID
        for (const ai of artistsInfos) {
            await doQuery('INSERT INTO Artisti SET ?', {
                NomeInArte: ai.alias,
                NomeCompleto: ai.fullName,
                Descrizione: ai.description,
                Etichetta: labelsInfos[Math.floor(Math.random() * labelsInfos.length)].name
            })
            lastID = await doQuery('SELECT LAST_INSERT_ID()')
            let artistID = lastID['LAST_INSERT_ID()']
            for await (const gai of ai.genres) {
                await doQuery('INSERT INTO Generi SET ?', {
                    Tipo: gai
                })
                lastID = await doQuery('SELECT LAST_INSERT_ID()')
                let genreArtID = lastID['LAST_INSERT_ID()']
                await doQuery('INSERT INTO GeneriArtista SET ?', {
                    Artista: artistID,
                    Genere: genreArtID
                })
            }
            for await (const a of ai.albums) {
                await doQuery('INSERT INTO Album SET ?', {
                    Titolo: a.title,
                    Anno: a.releaseYear
                })
                lastID = await doQuery('SELECT LAST_INSERT_ID()')
                let albumID = lastID['LAST_INSERT_ID()']
                await doQuery('INSERT INTO AlbumArtista SET ?', {
                    Album: albumID,
                    Artista: artistID
                })
                for await (const ga of a.genres) {
                    await doQuery('INSERT INTO Generi SET ?', {
                        Tipo: ga
                    })
                    lastID = await doQuery('SELECT LAST_INSERT_ID()')
                    let genreAlbID = lastID['LAST_INSERT_ID()']
                    await doQuery('INSERT INTO GeneriAlbum SET ?', {
                        Album: albumID,
                        Genere: genreAlbID
                    })
                }
                for await (const t of a.tracks) {
                    await doQuery('INSERT INTO Brani SET ?', {
                        Titolo: t.title,
                        Durata: t.length,
                        DataPubblicazione: t.releaseDate
                    })
                    lastID = await doQuery('SELECT LAST_INSERT_ID()')
                    let trackID = lastID['LAST_INSERT_ID()']
                    await doQuery('INSERT INTO BraniArtista SET ?', {
                        Brano: trackID,
                        Artista: artistID
                    })
                    await doQuery('INSERT INTO BraniAlbum SET ?', {
                        Brano: trackID,
                        Album: albumID
                    })
                    for await (const gt of t.genres) {
                        await doQuery('INSERT INTO Generi SET ?', {
                            Tipo: gt
                        })
                        lastID = await doQuery('SELECT LAST_INSERT_ID()')
                        let genreTraID = lastID['LAST_INSERT_ID()']
                        await doQuery('INSERT INTO GeneriBrano SET ?', {
                            Brano: trackID,
                            Genere: genreTraID
                        })
                    }
                }
            }
        }
        console.timeEnd("Inserted in")
    }, 10000)
})