const fs = require('fs')
const axios = require('axios').default;

// Explore Pokemon URLs
async function exploreURLs() {
    let urlPokemonList = `https://pokeapi.co/api/v2/pokemon/`;
    let pokemonList = { next: urlPokemonList };

    while (true) {
        
        let response = await axios.get(pokemonList.next);
        pokemonList = response.data;

        for (let i in pokemonList.results) {
            let pokemonUrl = pokemonList.results[i].url;
            console.log(pokemonUrl);
            // axios.get(pokemonUrl)
            // .then((pokemon) => {
            //     pokemon = pokemon.data;
            //     console.log(pokemon.sprites.other["official-artwork"]["front_default"]);
            // });
        }

        if (pokemonList.next === undefined
        ||  pokemonList.next === ""
        ||  pokemonList.next === null) break;
    }
}

// Figured out it was always the same form in the link, just changing pokemon number
// Generate images
async function downloadImages() {
    let intervalLeft = 0, i;
    for (i = 1; i <= 10220; i ++) {
        try {
            let response = await axios({
                method: "get",
                url: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${i}.png`,
                responseType: "stream"
            });
            response.data.pipe(fs.createWriteStream(`./images/${i}.png`));
            intervalLeft = intervalLeft == 0? i: intervalLeft;
        }
        catch(err) {
            //console.log(`Error ${i}: ${err}`);
            if (intervalLeft !== 0) {
                console.log(`Interval Good: ${intervalLeft} - ${i-1}`);
                intervalLeft = 0;
            }
        }
    }
    console.log(`Interval Good: ${intervalLeft} - ${i-1}`);
}

// Figured out many of them did not have image,
// so I just omitted ranges where there were no images

// Generate metadata
async function metadata() {
    for (let i = 1; i <= 10220; i ++) {
        if (i > 898 && i < 10001) continue;
        if (i > 10127 && i < 10130) continue;
        if (i > 10145 && i < 10147) continue;
        if (i > 10152 && i < 10155) continue;

        await axios(`https://pokeapi.co/api/v2/pokemon/${i}`)
        .then((response) => {
            console.log(i);
            response = response.data;
            let attributes = [
                {
                    "trait_type": "Weight",
                    "value": response.weight
                },
                {
                    "trait_type": "Height",
                    "value": response.height
                }
            ];
            
            response.stats.map((stat) => {
                attributes.push({
                    "trait_type": stat.stat.name, 
                    "value": stat.base_stat
                });
            });

            for (let x in response.types) {
                attributes.push({
                    "trait_type": `Type ${response.types[x].slot}`,
                    "value": response.types[x].type.name
                });
            }

            let metadata = {
                name: response.name,
                image: `https://raw.githubusercontent.com/Pokemon-Crypto-Cards/demo/master/images/${i}.png`,
                description: `#${i}`,
                attributes: attributes
            };

            fs.writeFile(`./metadata/${i}.json`, JSON.stringify(metadata), (err) => {
                if (err) console.log(err);
            });
        })
        .catch((err) => {
            console.log(`Error <${i}>: ${err}`);
        })
    }
}

// TODO: Instead of running them in this order, 
// there could be just one run that saves images and metadata. 

// exploreURLs();
// downloadImages();
// metadata();