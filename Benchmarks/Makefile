serve: FORCE
	rm -f generated.js
	echo "ALL_BENCHMARKS=[" > generated.js
	cat v1.6.json >> generated.js
	echo -n "," >> generated.js
	cat v2.4.4.json >> generated.js
	echo -n "," >> generated.js
	cat v3.1.2.json >> generated.js
	echo "," >> generated.js
	cat 4.1.0.json >> generated.js
	echo "];" >> generated.js
	./extract_git_data.sh >> generated.js
	echo "COMMIT_STATS = " >> generated.js
	./extract_tuples.py >> generated.js
	echo ";" >> generated.js
	python -m http.server 8001
FORCE: ;

format:
	rome format script.js --verbose --write --quote-style double --indent-style space --indent-size 2
updatejs:
	rm -f chart.js
	wget https://cdn.jsdelivr.net/npm/chart.js
