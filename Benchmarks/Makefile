serve: FORCE
	rm -f generated.js
	echo "ALL_BENCHMARKS=[" > generated.js
	cat v1.0.json >> generated.js
	echo -n "," >> generated.js
	cat v1.1.json >> generated.js
	echo -n "," >> generated.js
	cat v1.2.json >> generated.js
	echo -n "," >> generated.js
	cat v1.2.1.json >> generated.js
	echo -n "," >> generated.js
	cat v1.3.json >> generated.js
	echo -n "," >> generated.js
	cat v1.4.json >> generated.js
	echo -n "," >> generated.js
	cat v1.4.1.json >> generated.js
	echo "];" >> generated.js
	python -m http.server
FORCE: ;

format:
	rome format script.js --verbose --write --quote-style double --indent-style space --indent-size 2
updatejs:
	rm -f chart.js
	wget https://cdn.jsdelivr.net/npm/chart.js
