async function handleFileSelect(event) {
	document.getElementById("fileContent").innerHTML = "";
	const files = event.target.files;
	const contents = [];

	const promises = [];

	for (const element of files) {
		const reader = new FileReader();

		const promise = new Promise((resolve, reject) => {
			reader.onload = (event) => {
				const fileContents = event.target.result;
				contents.push(JSON.parse(fileContents));
				resolve();
			};
			reader.readAsText(element);
		});

		promises.push(promise);
	}
	await Promise.all(promises);
	contents.sort((a, b) => {
		const timeA = a.time;
		const timeB = b.time;
		if (timeA < timeB) return -1;
		if (timeA > timeB) return 1;
		return 0;
	});
	const datasets = {};
	const insns = {};
	const labels = [];
	for (const content of contents) {
		labels.push(content.name);
		for (const elem of Object.keys(content.data)) {
			const value = content.data[elem];
			if (!(elem in datasets)) {
				datasets[elem] = [];
				insns[elem] = [];
			}
			datasets[elem].push(value.stats.durations);
			insns[elem].push(value.insn_count);
		}
	}
	for (const project in datasets) {
		const projectNameHeading = document.createElement("h1");
		projectNameHeading.textContent = project;
		document.getElementById("fileContent").appendChild(projectNameHeading);

		const durationChartContainer = document.createElement("div");
		durationChartContainer.className = "chart-container";
		document.getElementById("fileContent").appendChild(durationChartContainer);

		const durationChartCanvas = document.createElement("canvas");
		durationChartContainer.appendChild(durationChartCanvas);

		const scatter = [];
		for (let i = 0; i < datasets[project].length; i++) {
			for (const element of datasets[project][i]) {
				scatter.push({ x: i + 1, y: element });
			}
		}
		scatter.sort();

		new Chart(durationChartCanvas, {
			type: "violin",
			data: {
				labels: labels,
				datasets: [
					{
						label: "Duration (In ms)",
						data: datasets[project],
						backgroundColor: "rgba(54, 162, 235, 0.5)",
						borderColor: "rgba(54, 162, 235, 1)",
						borderWidth: 1,
					},
				],
			},
			options: {
				scales: {
					x: {
						ticks: {
							stepSize: 1,
						},
						max: labels.length + 1,
						min: -1,
					},
					y: {
						beginAtZero: true,
						title: {
							display: true,
							text: "Duration",
						},
					},
				},
			},
		});

		const scatterChartContainer = document.createElement("div");
		scatterChartContainer.className = "chart-container";
		document.getElementById("fileContent").appendChild(scatterChartContainer);

		const scatterChartCanvas = document.createElement("canvas");
		scatterChartContainer.appendChild(scatterChartCanvas);

		new Chart(scatterChartCanvas, {
			type: "scatter",
			data: {
				labels: labels,
				datasets: [
					{
						label: "Duration (In ms, points)",
						data: scatter,
						backgroundColor: "rgba(154, 162, 235, 0.5)",
						borderColor: "rgba(254, 162, 235, 1)",
						borderWidth: 1,
					},
				],
			},
			options: {
				scales: {
					y: {
						beginAtZero: true,
						title: {
							display: true,
							text: "Duration",
						},
					},
				},
			},
		});

		// Create a chart for instruction count
		const insnsChartContainer = document.createElement("div");
		insnsChartContainer.className = "chart-container";
		document.getElementById("fileContent").appendChild(insnsChartContainer);

		const insnsChartCanvas = document.createElement("canvas");
		insnsChartContainer.appendChild(insnsChartCanvas);

		new Chart(insnsChartCanvas, {
			type: "bar",
			data: {
				labels: labels,
				datasets: [
					{
						label: "Number of Instructions",
						data: insns[project],
						backgroundColor: "rgba(255, 99, 132, 0.5)",
						borderColor: "rgba(255, 99, 132, 1)",
						borderWidth: 1,
					},
				],
			},
			options: {
				scales: {
					y: {
						beginAtZero: true,
						title: {
							display: true,
							text: "Instruction Count",
						},
					},
				},
			},
		});
	}
}
