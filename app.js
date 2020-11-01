const express = require('express');
const pug = require('pug');
const Adler32 = require("adler32-js")
const morgan = require("morgan"); // logging
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();

const path = require('path');
const public_folder = path.join(__dirname, 'public');
const static_folder = path.join(__dirname, 'static_priv');

const app = express();
app.use("/p", express.static(public_folder));
app.use(morgan("common"));
app.use(bodyParser.urlencoded({extended: true}));

var db = new sqlite3.Database(
	path.join(__dirname, "data.db"),
	sqlite3.OPEN_READWRITE,
	(err) => {
		if (err) {
			console.log("Database connection error");
		}
		else {
			console.log("Database connected");
		}
});


app.get("/", (req, res) => {
	res.send(pug.renderFile(`${static_folder}/index.pug`));
});

app.post("/generate", (req, res) => {
	if (req.body.url.match(/^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()!@:%_\+.~#?&\/\/=]*)$/)) {
		// valid url was given
		//var suburl = crypto.createHash("sha256").update(req.body.url).digest("hex");
		adler_hash = new Adler32();
		adler_hash.update(req.body.url);
		var hash = adler_hash.digest("hex");

		// add to database if it's not in there already
		db.run(
			"INSERT INTO suburls(hash, suburl) VALUES(?, ?)",
			[hash, req.body.url],
			(err) => {
				if (err) {
					// might fail because of UNIQUE constraint, this is fine.
					console.log(err.message);
				}
				else {
					console.log("Inserted row!");
				}
			}
		);

		//suburl_db[hash] = req.body.url;
		return res.send(pug.renderFile(
			`${static_folder}/index.pug`,
			{suburl: hash}
		));
	}
	else {
		return res.status(400).send(
			pug.renderFile(
				`${static_folder}/index.pug`,
				{error_alert: "Invalid URL was given."}
			)
		);
	}
});

app.get("/c/:code", (req, res) => {
	// query db
	db.get(
		"SELECT hash, suburl FROM suburls WHERE hash = ?",
		[req.params.code],
		(err, row) => {
			if (err) {
				return res.send(pug.renderFile(`${static_folder}/index.pug`, {error_alert: err.message}));
			}
			else if (row) {
				// found result
				var {hash, suburl} = row;
				res.redirect(suburl);
			}
			else {
				res.send(pug.renderFile(`${static_folder}/index.pug`, {error_alert: "Couldn't find the specified URL"}));
			}
		}
	);
});

app.get("/database", (req, res) => {
	// this endpoint is purely for debugging purposes and is definitely open to XSS :D
	db.all(
		"SELECT hash, suburl FROM suburls",
		[],
		(err, rows) => {
			if (err) {
				console.log(err.message);
			}
			return res.send(
				pug.renderFile(
					`${static_folder}/database.pug`,
					{rows: rows}
				)
			);
		}
	)
});


app.listen(80, () => {
	console.log("Listening");
});
