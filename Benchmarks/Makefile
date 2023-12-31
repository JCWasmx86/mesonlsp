serve: FORCE
	rm -f generated.js
	echo "ALL_BENCHMARKS=[" > generated.js
	cat v1.0.json >> generated.js
	echo -n "," >> generated.js
	cat v1.1.json >> generated.js
	echo -n "," >> generated.js
	cat v1.2.json >> generated.js
	echo -n "," >> generated.js
	cat v1.3.json >> generated.js
	echo -n "," >> generated.js
	cat v1.4.json >> generated.js
	echo -n "," >> generated.js
	cat v1.4.1.json >> generated.js
	echo -n "," >> generated.js
	cat v1.5.json >> generated.js
	echo -n "," >> generated.js
	cat v1.5.1.json >> generated.js
	echo -n "," >> generated.js
	cat v1.6.json >> generated.js
	echo -n "," >> generated.js
	cat v2.0.json >> generated.js
	echo -n "," >> generated.js
	cat v2.1.json >> generated.js
	echo -n "," >> generated.js
	cat v2.2.json >> generated.js
	echo -n "," >> generated.js
	cat v2.3.json >> generated.js
	echo -n "," >> generated.js
	cat v2.3.1.json >> generated.js
	echo -n "," >> generated.js
	cat v2.4.json >> generated.js
	echo -n "," >> generated.js
	cat v2.4.1.json >> generated.js
	echo -n "," >> generated.js
	cat v2.4.2.json >> generated.js
	echo -n "," >> generated.js
	cat v2.4.4.json >> generated.js
	echo -n "," >> generated.js
	cat v3.0.0.json >> generated.js
	echo -n "," >> generated.js
	cat v3.1.0.json >> generated.js
	echo "," >> generated.js
	cat v3.1.2.json >> generated.js
	echo "," >> generated.js
	cat prec++.json >> generated.js
	echo "];" >> generated.js
	./extract_git_data.sh >> generated.js
	echo "COMMIT_STATS = " >> generated.js
	./extract_tuples.py >> generated.js
	echo ";" >> generated.js
	python -m http.server
FORCE: ;

format:
	rome format script.js --verbose --write --quote-style double --indent-style space --indent-size 2
updatejs:
	rm -f chart.js
	wget https://cdn.jsdelivr.net/npm/chart.js
