serve: FORCE
	rm -f generated.js
	echo "ALL_BENCHMARKS=[" > generated.js
	cat v1.0.json >> generated.js
	echo -n "," >> generated.js
	cat v1.1.json >> generated.js
	echo -n "," >> generated.js
	cat v1.2.json >> generated.js
	echo "];" >> generated.js
	python -m http.server
FORCE: ;
