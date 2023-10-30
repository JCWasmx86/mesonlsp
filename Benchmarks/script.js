ELEMENT_NAMES = [
  "mesa",
  "gnome-builder",
  "qemu",
  "GNOME-Builder-Plugins",
  "gtk",
  "postgres",
];

tempAllocGraph = null;
allocGraph = null;

function openTab(evt, tabName) {
  const tabcontent = document.getElementsByClassName("tabcontent");
  for (let i = 0; i < tabcontent.length; i++) {
    tabcontent[i].style.display = "none";
  }
  const tablinks = document.getElementsByClassName("tablinks");
  for (let i = 0; i < tablinks.length; i++) {
    tablinks[i].className = tablinks[i].className.replace(" active", "");
  }
  document.getElementById(tabName).style.display = "block";
  evt.currentTarget.className += " active";
}

function findProject(obj, name) {
  for (const p in obj.projects) {
    if (obj.projects[p].name === name) return obj.projects[p];
  }
}

function percentify(oldValue, newValue) {
  return `${((newValue / oldValue) * 100 - 100).toFixed(2)}%`;
}

function attachChart(name, label, data, beginAtZero) {
  const tags = ALL_BENCHMARKS.map((a) => a.commit);
  const ctx = document.getElementById(name);
  const colors = ["#1c71d8", "#c01c28", "#613583", "#26a269", "#000000"];
  const realBeginAtZero =
    typeof beginAtZero !== "undefined" ? beginAtZero : true;
  new Chart(ctx, {
    type: "bar",
    data: {
      labels: tags,
      datasets: [
        {
          label: label,
          data: data,
          backgroundColor: colors,
        },
      ],
    },
    options: {
      scales: {
        y: {
          beginAtZero: realBeginAtZero,
        },
      },
    },
  });
}

function avgData(key) {
  return ALL_BENCHMARKS.map((a) => a.projects)
    .map((a) => a.map((b) => parseFloat(`${b[key]}`.replace("M", ""))))
    .map((a) => a.reduce((partialSum, b) => partialSum + b, 0))
    .map((a) => a / ELEMENT_NAMES.length);
}

function avgAllocationsPerSecond() {
  const allocations = avgData("memory_allocations");
  const parsing = avgData("parsing");
  return allocations.map((e, i) => (e * 10) / (parsing[i] / 1000));
}

function avgTemporaryAllocationsPerSecond() {
  const allocations = avgData("temporary_memory_allocations");
  const parsing = avgData("parsing");
  // Divided by 1000 to convert ms -> s
  // Multiplied by 10, as performance is measured doing 10 * 100
  // but heaptrack is 1 * 100
  return allocations.map((e, i) => (e * 10) / (parsing[i] / 1000));
}

function appendHr(parent) {
  const hr = document.createElement("hr");
  parent.append(hr);
}

function initHTML() {
  const parent = document.getElementById("Overview");
  appendHr(parent);
  for (const element of ELEMENT_NAMES) {
    const ctxName = element.replaceAll("-", "_");
    const detail = document.createElement("details");
    const summary = document.createElement("summary");
    summary.textContent = `Measurements for ${element}`;
    const resultDiv = document.createElement("div");
    resultDiv.classList.add("horizontal");
    for (const suffix of ["", "_allocs", "_tmp_allocs", "_rss", "_heap"]) {
      const childDiv = document.createElement("div");
      childDiv.classList.add("child");
      const canvas = document.createElement("canvas");
      canvas.id = ctxName + suffix;
      childDiv.append(canvas);
      resultDiv.append(childDiv);
    }
    detail.append(summary);
    detail.append(resultDiv);
    parent.insertBefore(detail, document.getElementById("anchor"));
    const hr = document.createElement("hr");
    parent.insertBefore(hr, document.getElementById("anchor"));
  }
}

function regression(pts) {
  let xs = 0;
  let ys = 0;
  let xxs = 0;
  let xys = 0;
  let yys = 0;
  for (let i = 0; i < pts.length; i++) {
    xs += pts[i].x;
    ys += pts[i].y;
    xxs += pts[i].x * pts[i].x;
    xys += pts[i].x * pts[i].y;
    yys += pts[i].y * pts[i].y;
  }
  const div = pts.length * xxs - xs * xs;
  const gain = (pts.length * xys - xs * ys) / div;
  const offset = (ys * xxs - xs * xys) / div;
  return { a: gain, b: offset };
}

function fillPerformanceChart() {
  const colors = ["#1c71d8", "#c01c28", "#613583", "#26a269", "#000000"];
  const arr = [];
  for (let i = 0; i < ALL_BENCHMARKS.length; i++) {
    for (const element of ELEMENT_NAMES) {
      const counts = ALL_BENCHMARKS.map((a) => findProject(a, element).parsing);
      const diff = counts[i + 1] / counts[i];
      arr.push({ x: i, y: diff * 100 });
    }
    let counts = ALL_BENCHMARKS.map((a) => a.misc.parsing);
    let diff = counts[i + 1] / counts[i];
    arr.push({ x: i, y: diff * 100 });
    counts = ALL_BENCHMARKS.map((a) => a.floss.gnome.parsing);
    diff = counts[i + 1] / counts[i];
    arr.push({ x: i, y: diff * 100 });
    counts = ALL_BENCHMARKS.map((a) => a.floss.elementary.parsing);
    diff = counts[i + 1] / counts[i];
    arr.push({ x: i, y: diff * 100 });
  }
  const ctx = document.getElementById("performanceChanges");
  new Chart(ctx, {
    type: "scatter",
    data: {
      datasets: [
        {
          label: "Performance changes to prior version",
          data: arr,
        },
      ],
    },
    options: {
      scales: {
        x: {
          type: "linear",
        },
        y: {
          beginAtZero: true,
        },
      },
    },
  });
}

function createOverviewCharts() {
  initHTML();
  const tags = ALL_BENCHMARKS.map((a) => a.commit);
  const colors = ["#1c71d8", "#c01c28", "#613583", "#26a269", "#000000"];
  attachChart(
    "sizeChart",
    "Size in bytes (Unstripped)",
    ALL_BENCHMARKS.map((a) => a.size),
    false,
  );
  attachChart(
    "strippedSizeChart",
    "Size in bytes (Stripped)",
    ALL_BENCHMARKS.map((a) => a.stripped_size),
    false,
  );
  attachChart(
    "avgAllocationsPerSecond",
    "Average allocations per second",
    avgAllocationsPerSecond(),
  );
  attachChart(
    "avgTemporaryAllocationsPerSecond",
    "Average temporary allocations per second",
    avgTemporaryAllocationsPerSecond(),
  );
  attachChart(
    "avgPerformance",
    "Average performance (In ms)",
    avgData("parsing"),
  );
  attachChart(
    "avgMemoryAllocations",
    "Average memory allocations",
    avgData("memory_allocations"),
  );
  attachChart(
    "avgTempMemoryAllocations",
    "Average temporary memory allocations",
    avgData("temporary_memory_allocations"),
    false,
  );
  attachChart("avgRss", "Peak RSS (In MB)", avgData("peak_rss"));
  attachChart("avgHeap", "Peak Heap (In MB)", avgData("peak_heap"));
  fillPerformanceChart();
  for (const element of ELEMENT_NAMES) {
    ctx = document.getElementById(element.replaceAll("-", "_"));
    attachChart(
      element.replaceAll("-", "_"),
      "Time required for parsing (In ms)",
      ALL_BENCHMARKS.map((a) => findProject(a, element).parsing),
    );
    attachChart(
      `${element}_allocs`.replaceAll("-", "_"),
      "Memory allocations",
      ALL_BENCHMARKS.map((a) => findProject(a, element).memory_allocations),
    );
    attachChart(
      `${element}_tmp_allocs`.replaceAll("-", "_"),
      "Temporary memory allocations",
      ALL_BENCHMARKS.map(
        (a) => findProject(a, element).temporary_memory_allocations,
      ),
      false,
    );
    attachChart(
      `${element}_rss`.replaceAll("-", "_"),
      "Peak RSS (In MB)",
      ALL_BENCHMARKS.map((a) =>
        findProject(a, element).peak_rss.replace("M", ""),
      ),
    );
    attachChart(
      `${element}_heap`.replaceAll("-", "_"),
      "Peak Heap (In MB)",
      ALL_BENCHMARKS.map((a) =>
        findProject(a, element).peak_heap.replace("M", ""),
      ),
    );
  }
  attachChart(
    "misc",
    "Time required for parsing (In ms)",
    ALL_BENCHMARKS.map((a) => a.misc.parsing),
  );
  attachChart(
    "misc_allocs",
    "Memory allocations",
    ALL_BENCHMARKS.map((a) => a.misc.memory_allocations),
  );
  attachChart(
    "misc_tmp_allocs",
    "Temporary memory allocations",
    ALL_BENCHMARKS.map((a) => a.misc.temporary_memory_allocations),
    false,
  );
  attachChart(
    "misc_rss",
    "Peak RSS (In MB)",
    ALL_BENCHMARKS.map((a) => a.misc.peak_rss.replace("M", "")),
  );
  attachChart(
    "misc_heap",
    "Peak Heap (In MB)",
    ALL_BENCHMARKS.map((a) => a.misc.peak_heap.replace("M", "")),
  );

  for (const element of ["gnome", "elementary"]) {
    ctx = document.getElementById(element.replaceAll("-", "_"));
    attachChart(
      element.replaceAll("-", "_"),
      "Time required for parsing (In ms)",
      ALL_BENCHMARKS.map((a) => a.floss[element].parsing),
    );
    attachChart(
      `${element}_allocs`.replaceAll("-", "_"),
      "Memory allocations",
      ALL_BENCHMARKS.map((a) => a.floss[element].memory_allocations),
    );
    attachChart(
      `${element}_tmp_allocs`.replaceAll("-", "_"),
      "Temporary memory allocations",
      ALL_BENCHMARKS.map((a) => a.floss[element].temporary_memory_allocations),
      false,
    );
    attachChart(
      `${element}_rss`.replaceAll("-", "_"),
      "Peak RSS (In MB)",
      ALL_BENCHMARKS.map((a) => a.floss[element].peak_rss.replace("M", "")),
    );
    attachChart(
      `${element}_heap`.replaceAll("-", "_"),
      "Peak Heap (In MB)",
      ALL_BENCHMARKS.map((a) => a.floss[element].peak_heap.replace("M", "")),
    );
  }
}

function appendTr(tr, txt) {
  const td = document.createElement("td");
  td.appendChild(document.createTextNode(txt));
  if (txt[0] === "-" && `${txt}`.endsWith("%")) {
    td.style.backgroundColor = "#26a269";
  } else if (txt[0] !== "-" && `${txt}`.endsWith("%")) {
    td.style.backgroundColor = "#e01b24";
  }
  tr.appendChild(td);
}

function appendTh(tr, txt) {
  const th = document.createElement("th");
  th.appendChild(document.createTextNode(txt));
  tr.appendChild(th);
}

function changedVersions() {
  const oldData = ALL_BENCHMARKS[document.getElementById("versions").value];
  const newData = ALL_BENCHMARKS[document.getElementById("versions2").value];
  const tableDiv = document.getElementById("dynamicTable");
  while (tableDiv.hasChildNodes()) {
    tableDiv.removeChild(tableDiv.lastChild);
  }
  const table = document.createElement("table");
  table.border = "1";
  const tableBody = document.createElement("tbody");
  table.appendChild(tableBody);
  let tr = document.createElement("tr");
  tableBody.appendChild(tr);
  appendTh(tr, "Measurement");
  appendTh(tr, oldData.commit);
  appendTh(tr, newData.commit);
  appendTh(tr, "Percentage");
  tr = document.createElement("tr");
  tableBody.appendChild(tr);
  appendTr(tr, "Binary Size");
  appendTr(tr, oldData.size);
  appendTr(tr, newData.size);
  appendTr(tr, percentify(oldData.size, newData.size));
  tr = document.createElement("tr");
  tableBody.appendChild(tr);
  appendTr(tr, "Binary Size (Stripped)");
  appendTr(tr, oldData.stripped_size);
  appendTr(tr, newData.stripped_size);
  appendTr(tr, percentify(oldData.stripped_size, newData.stripped_size));
  tableDiv.appendChild(table);
  for (const element of ELEMENT_NAMES) {
    const p = findProject(oldData, element);
    const p1 = findProject(newData, element);
    tr = document.createElement("tr");
    tableBody.appendChild(tr);
    appendTr(tr, `Parsing ${element} 10 * 100 times`);
    appendTr(tr, p.parsing);
    appendTr(tr, p1.parsing);
    appendTr(tr, percentify(p.parsing, p1.parsing));
  }
  for (const element of ELEMENT_NAMES) {
    const p = findProject(oldData, element);
    const p1 = findProject(newData, element);
    tr = document.createElement("tr");
    tableBody.appendChild(tr);
    appendTr(tr, `Memory allocations during parsing ${element}`);
    appendTr(tr, p.memory_allocations);
    appendTr(tr, p1.memory_allocations);
    appendTr(tr, percentify(p.memory_allocations, p1.memory_allocations));
  }
  for (const element of ELEMENT_NAMES) {
    const p = findProject(oldData, element);
    const p1 = findProject(newData, element);
    tr = document.createElement("tr");
    tableBody.appendChild(tr);
    appendTr(tr, `Temporary memory allocations during parsing ${element}`);
    appendTr(tr, p.temporary_memory_allocations);
    appendTr(tr, p1.temporary_memory_allocations);
    appendTr(
      tr,
      percentify(
        p.temporary_memory_allocations,
        p1.temporary_memory_allocations,
      ),
    );
  }
  for (const element of ELEMENT_NAMES) {
    const p = findProject(oldData, element);
    const p1 = findProject(newData, element);
    tr = document.createElement("tr");
    tableBody.appendChild(tr);
    appendTr(tr, `Peak heap usage during parsing ${element}`);
    appendTr(tr, p.peak_heap);
    appendTr(tr, p1.peak_heap);
    appendTr(
      tr,
      percentify(p.peak_heap.replace("M", ""), p1.peak_heap.replace("M", "")),
    );
  }
  for (const element of ELEMENT_NAMES) {
    const p = findProject(oldData, element);
    const p1 = findProject(newData, element);
    tr = document.createElement("tr");
    tableBody.appendChild(tr);
    appendTr(
      tr,
      `Peak RSS during parsing ${element} (Includes heaptrack overhead)`,
    );
    appendTr(tr, p.peak_rss);
    appendTr(tr, p1.peak_rss);
    appendTr(
      tr,
      percentify(p.peak_rss.replace("M", ""), p1.peak_rss.replace("M", "")),
    );
  }
  tr = document.createElement("tr");
  tableBody.appendChild(tr);
  appendTr(tr, "Parsing miscellaneous projects");
  appendTr(tr, oldData.misc.parsing);
  appendTr(tr, newData.misc.parsing);
  appendTr(tr, percentify(oldData.misc.parsing, newData.misc.parsing));
  tr = document.createElement("tr");
  tableBody.appendChild(tr);
  appendTr(tr, "Memory allocations during parsing miscellaneous projects");
  appendTr(tr, oldData.misc.memory_allocations);
  appendTr(tr, newData.misc.memory_allocations);
  appendTr(
    tr,
    percentify(
      oldData.misc.memory_allocations,
      newData.misc.memory_allocations,
    ),
  );
  tr = document.createElement("tr");
  tableBody.appendChild(tr);
  appendTr(
    tr,
    "Temporary memory allocations during parsing miscellaneous projects",
  );
  appendTr(tr, oldData.misc.temporary_memory_allocations);
  appendTr(tr, newData.misc.temporary_memory_allocations);
  appendTr(
    tr,
    percentify(
      oldData.misc.temporary_memory_allocations,
      newData.misc.temporary_memory_allocations,
    ),
  );
  tr = document.createElement("tr");
  tableBody.appendChild(tr);
  appendTr(tr, "Peak heap usage during parsing miscellaneous projects");
  appendTr(tr, oldData.misc.peak_heap.replace("M", ""));
  appendTr(tr, newData.misc.peak_heap.replace("M", ""));
  appendTr(
    tr,
    percentify(
      oldData.misc.peak_heap.replace("M", ""),
      newData.misc.peak_heap.replace("M", ""),
    ),
  );
  tr = document.createElement("tr");
  tableBody.appendChild(tr);
  appendTr(tr, "Peak RSS usage during parsing miscellaneous projects");
  appendTr(tr, oldData.misc.peak_rss.replace("M", ""));
  appendTr(tr, newData.misc.peak_rss.replace("M", ""));
  appendTr(
    tr,
    percentify(
      oldData.misc.peak_rss.replace("M", ""),
      newData.misc.peak_rss.replace("M", ""),
    ),
  );
  const colors = ["#1c71d8", "#c01c28", "#613583", "#000000"];
  let ctx = document.getElementById("alloc_perf");
  let oldScatter = [];
  let newScatter = [];
  for (const element of ELEMENT_NAMES) {
    const p = findProject(oldData, element);
    const p1 = findProject(newData, element);
    oldScatter.push({ x: p.parsing, y: p.memory_allocations });
    newScatter.push({ x: p1.parsing, y: p1.memory_allocations });
  }
  oldScatter.push({
    x: oldData.floss.gnome.parsing,
    y: oldData.floss.gnome.memory_allocations,
  });
  newScatter.push({
    x: newData.floss.gnome.parsing,
    y: newData.floss.gnome.memory_allocations,
  });
  oldScatter.push({
    x: oldData.floss.elementary.parsing,
    y: oldData.floss.elementary.memory_allocations,
  });
  newScatter.push({
    x: newData.floss.elementary.parsing,
    y: newData.floss.elementary.memory_allocations,
  });
  oldScatter.push({
    x: oldData.misc.parsing,
    y: oldData.misc.memory_allocations,
  });
  newScatter.push({
    x: newData.misc.parsing,
    y: newData.misc.memory_allocations,
  });
  if (allocGraph !== null) {
    allocGraph.destroy();
    tempAllocGraph.destroy();
  }
  let highestX = -1;
  for (let i = 0; i < oldScatter.length; i++) {
    highestX = Math.max(highestX, Math.max(oldScatter[i].x, newScatter[i].x));
  }
  let oldGraphParams = regression(oldScatter);
  let oldGraph = [
    { x: 0, y: oldGraphParams.b },
    { x: highestX, y: oldGraphParams.a * highestX + oldGraphParams.b },
  ];
  console.log(`Memory allocations, old: ${JSON.stringify(oldGraphParams)}`);
  let newGraphParams = regression(newScatter);
  let newGraph = [
    { x: 0, y: newGraphParams.b },
    { x: highestX, y: newGraphParams.a * highestX + newGraphParams.b },
  ];
  console.log(`Memory allocations, new: ${JSON.stringify(newGraphParams)}`);
  allocGraph = new Chart(ctx, {
    type: "scatter",
    data: {
      datasets: [
        {
          label: `Parsing - Memory allocations mapping: ${oldData.commit}`,
          type: "scatter",
          data: oldScatter,
        },
        {
          label: `Parsing - Memory allocations mapping: ${newData.commit}`,
          type: "scatter",
          data: newScatter,
        },
        {
          label: `Approx. Parsing - Memory allocations mapping: ${oldData.commit}`,
          type: "line",
          data: oldGraph,
        },
        {
          label: `Approx. Parsing - Memory allocations mapping: ${newData.commit}`,
          type: "line",
          data: newGraph,
        },
      ],
    },
    options: {
      scales: {
        x: {
          type: "linear",
        },
        y: {
          beginAtZero: true,
        },
      },
    },
  });
  ctx = document.getElementById("temp_alloc_perf");
  oldScatter = [];
  newScatter = [];
  for (const element of ELEMENT_NAMES) {
    const p = findProject(oldData, element);
    const p1 = findProject(newData, element);
    oldScatter.push({ x: p.parsing, y: p.temporary_memory_allocations });
    newScatter.push({ x: p1.parsing, y: p1.temporary_memory_allocations });
  }
  oldScatter.push({
    x: oldData.floss.gnome.parsing,
    y: oldData.floss.gnome.temporary_memory_allocations,
  });
  newScatter.push({
    x: newData.floss.gnome.parsing,
    y: newData.floss.gnome.temporary_memory_allocations,
  });
  oldScatter.push({
    x: oldData.floss.elementary.parsing,
    y: oldData.floss.elementary.temporary_memory_allocations,
  });
  newScatter.push({
    x: newData.floss.elementary.parsing,
    y: newData.floss.elementary.temporary_memory_allocations,
  });
  oldScatter.push({
    x: oldData.misc.parsing,
    y: oldData.misc.temporary_memory_allocations,
  });
  newScatter.push({
    x: newData.misc.parsing,
    y: newData.misc.temporary_memory_allocations,
  });
  highestX = -1;
  for (let i = 0; i < oldScatter.length; i++) {
    highestX = Math.max(highestX, Math.max(oldScatter[i].x, newScatter[i].x));
  }
  oldGraphParams = regression(oldScatter);
  oldGraph = [
    { x: 0, y: oldGraphParams.b },
    { x: highestX, y: oldGraphParams.a * highestX + oldGraphParams.b },
  ];
  console.log(
    `Temporary memory allocations, old: ${JSON.stringify(oldGraphParams)}`,
  );
  newGraphParams = regression(newScatter);
  newGraph = [
    { x: 0, y: newGraphParams.b },
    { x: highestX, y: newGraphParams.a * highestX + newGraphParams.b },
  ];
  console.log(
    `Temporary memory allocations, new: ${JSON.stringify(newGraphParams)}`,
  );
  tempAllocGraph = new Chart(ctx, {
    type: "scatter",
    data: {
      datasets: [
        {
          label: `Parsing - Temporary memory allocations mapping: ${oldData.commit}`,
          data: oldScatter,
        },
        {
          label: `Parsing - Temporary memory allocations mapping: ${newData.commit}`,
          data: newScatter,
        },
        {
          label: `Approx. Parsing - Temporary memory allocations mapping: ${oldData.commit}`,
          type: "line",
          data: oldGraph,
        },
        {
          label: `Approx. Parsing - Temporary memory allocations mapping: ${newData.commit}`,
          type: "line",
          data: newGraph,
        },
      ],
    },
    options: {
      scales: {
        x: {
          type: "linear",
        },
        y: {
          beginAtZero: true,
        },
      },
    },
  });
}

function createChartCanvas(fullName, nameID) {
  const fullSpanOuter = document.createElement("span");
  const fullSpan = document.createElement("span");
  fullSpan.classList.add("horizontal");
  const h5 = document.createElement("h5");
  h5.innerHTML = fullName;
  fullSpanOuter.appendChild(h5);
  let chartDiv = document.createElement("div");
  chartDiv.classList.add("child");
  let canvasElem = document.createElement("canvas");
  canvasElem.setAttribute("id", nameID);
  chartDiv.appendChild(canvasElem);
  const allChartsDiv = document.getElementById("allCharts");
  fullSpan.appendChild(chartDiv);
  chartDiv = document.createElement("div");
  chartDiv.classList.add("child");
  canvasElem = document.createElement("canvas");
  canvasElem.setAttribute("id", `${nameID}_ppc`);
  chartDiv.appendChild(canvasElem);
  fullSpan.appendChild(chartDiv);
  fullSpanOuter.appendChild(fullSpan);
  allChartsDiv.appendChild(fullSpanOuter);
  allChartsDiv.appendChild(document.createElement("hr"));
}

function initAllProjectsPerformanceTable(obj) {
  const tags = ALL_BENCHMARKS.map((a) => a.commit).slice(1);
  const colors = ["#1c71d8", "#c01c28", "#613583", "#26a269", "#000000"];
  const arr = [];
  for (const [key, value] of Object.entries(obj)) {
    for (let i = 1; i < value.length; i++) {
      const diff = value[i] / value[i - 1];
      arr.push({ x: i, y: diff * 100 });
    }
  }
  const ctx = document.getElementById("allProjectsPerformance");
  new Chart(ctx, {
    type: "scatter",
    data: {
      labels: tags,
      datasets: [
        {
          label: "Performance changes to prior version",
          labels: tags,
          data: arr,
        },
      ],
    },
    options: {
      scales: {
        x: {
          type: "linear",
        },
        y: {
          beginAtZero: true,
        },
      },
    },
  });
}

function getColorByPercentage(percentage) {
  const colors = [
    "#ffffff", // No commits
    "#ffeb3b", // Low commits
    "#ffc107", // Medium commits
    "#ff5722", // High commits
  ];

  const colorIndex = Math.min(
    Math.floor(percentage * (colors.length - 1)),
    colors.length - 1,
  );
  return colors[colorIndex];
}

function percentifyArray(array) {
  const percentages = [0.0];
  for (let i = 1; i < ALL_BENCHMARKS.length; i++) {
    const newValue = array[i];
    const oldValue = array[i - 1];
    const per = ((newValue / oldValue) * 100 - 100).toFixed(2);
    percentages.push(per);
  }
  return percentages;
}
function initAllCharts() {
  const obj = {};
  let sum = undefined;
  for (const benchmark of ALL_BENCHMARKS) {
    for (const [key, value] of Object.entries(benchmark.quick)) {
      if (Object.hasOwn(obj, key)) {
        obj[key].push(value);
      } else {
        obj[key] = [value];
      }
    }
  }
  for (const [key, value] of Object.entries(obj)) {
    createChartCanvas(key, `chart_${key}`);
    attachChart(
      `chart_${key}`,
      `Time required for parsing ${key} (In ms)`,
      value,
    );
    attachChart(
      `chart_${key}_ppc`,
      `Time required for parsing ${key} (In percentage to previous version)`,
      percentifyArray(value),
    );
    if (sum === undefined) {
      sum = value;
    } else {
      sum = sum.map((num, idx) => num + value[idx]);
    }
  }
  attachChart("ppc", "Time required for parsing (In ms, summed up)", sum);
  const percentages = [0.0];
  for (let i = 1; i < ALL_BENCHMARKS.length; i++) {
    const newValue = sum[i];
    const oldValue = sum[i - 1];
    const per = ((newValue / oldValue) * 100 - 100).toFixed(2);
    percentages.push(per);
  }
  attachChart(
    "ppc_percentage",
    "Time required for parsing (In percentage to previous version)",
    percentages,
  );
  const tableDiv = document.getElementById("allChartsTable");
  const table = document.createElement("table");
  table.border = "1";
  const tableBody = document.createElement("tbody");
  table.appendChild(tableBody);
  let tr = document.createElement("tr");
  tableBody.appendChild(tr);
  appendTh(tr, "Project");
  for (const benchmark of ALL_BENCHMARKS) {
    appendTh(tr, benchmark.commit);
  }
  for (const [key, value] of Object.entries(obj)) {
    tr = document.createElement("tr");
    tableBody.appendChild(tr);
    appendTr(tr, key);
    for (let i = 0; i < value.length; i++) {
      if (i === 0) {
        appendTr(tr, value[0].toFixed(2));
      } else {
        const diff = value[i] - value[i - 1];
        const color = diff === 0 ? undefined : diff < 0 ? "#26a269" : "#e01b24";
        const td = document.createElement("td");
        if (color !== undefined) {
          td.style.backgroundColor = color;
        }
        td.appendChild(document.createTextNode(value[i].toFixed(2)));
        tr.appendChild(td);
      }
    }
  }
  tableDiv.appendChild(table);
  attachChart(
    "commits",
    "Commits",
    DIFFS.map((a) => a[3]),
  );
  attachChart(
    "filechanges",
    "Changed files",
    DIFFS.map((a) => a[0]),
  );
  const adds = DIFFS.map((a) => a[1]);
  const rms = DIFFS.map((a) => a[2]);
  const tags = ALL_BENCHMARKS.map((a) => a.commit);
  let ctx = document.getElementById("insertDeletes");
  new Chart(ctx, {
    type: "line",
    data: {
      labels: tags,
      datasets: [
        {
          label: "Insertions",
          data: adds,
        },
        {
          label: "Deletions",
          data: rms,
        },
      ],
    },
  });
  initAllProjectsPerformanceTable(obj);
  const days = Array(7).fill(0);
  const daynames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  for (let i = 0; i < DAYS.length; i++) {
    days[daynames.indexOf(DAYS[i][1])] = DAYS[i][0];
  }
  ctx = document.getElementById("days");
  new Chart(ctx, {
    type: "line",
    data: {
      labels: daynames,
      datasets: [
        {
          label: "No. of Commits",
          data: days,
        },
      ],
    },
  });
  const hours = Array.apply(null, Array(24)).map((x, i) => i);
  const hourCommits = Array(24).fill(0);
  for (let i = 0; i < HOURS.length; i++) {
    hourCommits[HOURS[i][1]] = HOURS[i][0];
  }
  console.log(hourCommits);
  ctx = document.getElementById("hours");
  new Chart(ctx, {
    type: "line",
    data: {
      labels: hours,
      datasets: [
        {
          label: "No. of Commits",
          data: hourCommits,
        },
      ],
    },
  });
  const maximumCommits = COMMIT_STATS.reduce((total, data) => {
    return Math.max(total, data.commits);
  }, 0);
  const daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  const container = document.getElementById("heatmap");
  for (const day of daysOfWeek) {
    const label = document.createElement("div");
    label.classList.add("heatmap-cell");
    label.textContent = day;
    document.getElementById("heatmap-container").appendChild(label);
    for (let hour = 0; hour < 24; hour++) {
      const cellData = COMMIT_STATS.find(
        (item) =>
          item.day === day && item.hour === hour.toString().padStart(2, "0"),
      );
      const cell = document.createElement("div");
      cell.classList.add("heatmap-cell");
      const percentage = (1.0 * cellData.commits) / maximumCommits;
      cell.style.backgroundColor = getColorByPercentage(percentage);
      cell.textContent = cellData.commits;
      container.appendChild(cell);
    }
  }
}
