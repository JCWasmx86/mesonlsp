ELEMENT_NAMES = [
  "mesa",
  "gnome-builder",
  "qemu",
  "GNOME-Builder-Plugins",
  "gtk",
  "postgres",
];

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
  beginAtZero = typeof beginAtZero !== "undefined" ? beginAtZero : true;
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
          beginAtZero: beginAtZero,
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
    let detail = document.createElement("details");
    let summary = document.createElement("summary");
    summary.textContent = "Measurements for " + element;
    const resultDiv = document.createElement("div");
    resultDiv.classList.add("horizontal");
    for (const suffix of ["", "_allocs", "_tmp_allocs", "_rss", "_heap"]) {
      let childDiv = document.createElement("div");
      childDiv.classList.add("child");
      let canvas = document.createElement("canvas");
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
}

function appendTr(tr, txt) {
  const td = document.createElement("td");
  td.appendChild(document.createTextNode(txt));
  if (txt[0] == "-" && (txt + "").endsWith("%")) {
    td.style.backgroundColor = "#26a269";
  } else if (txt[0] != "-" && (txt + "").endsWith("%")) {
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
}

function createChartCanvas(nameID) {
  const chartDiv = document.createElement("div");
  chartDiv.classList.add("child");
  chartDiv.classList.add("smallsize");
  const canvasElem = document.createElement("canvas");
  canvasElem.setAttribute("id", nameID);
  chartDiv.appendChild(canvasElem);
  const allChartsDiv = document.getElementById("allCharts");
  allChartsDiv.appendChild(chartDiv);
}

function initAllCharts() {
  const obj = {};
  let sum = undefined;
  for (const benchmark of ALL_BENCHMARKS) {
    for (const [key, value] of Object.entries(benchmark.quick)) {
      if (obj.hasOwnProperty(key)) {
        obj[key].push(value);
      } else {
        obj[key] = [value];
      }
    }
  }
  for (const [key, value] of Object.entries(obj)) {
    createChartCanvas(`chart_${key}`);
    attachChart(
      `chart_${key}`,
      `Time required for parsing ${key} (In ms)`,
      value,
    );
    if (sum === undefined) {
      sum = value;
    } else {
      sum.map(function (num, idx) {
        return num + value[idx];
      });
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
}
