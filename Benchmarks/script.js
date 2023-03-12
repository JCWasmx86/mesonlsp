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

function createOverviewCharts() {
  ctx = document.getElementById("sizeChart");
  const tags = ALL_BENCHMARKS.map((a) => a.commit);
  const colors = ["#1c71d8", "#c01c28", "#613583", "#26a269", "#000000"];
  new Chart(ctx, {
    type: "bar",
    data: {
      labels: tags,
      datasets: [
        {
          label: "Size in bytes (Unstripped)",
          data: ALL_BENCHMARKS.map((a) => a.size),
          backgroundColor: colors,
        },
      ],
    },
    options: {
      scales: {
        y: {
          beginAtZero: false,
        },
      },
    },
  });
  ctx = document.getElementById("strippedSizeChart");
  new Chart(ctx, {
    type: "bar",
    data: {
      labels: tags,
      datasets: [
        {
          label: "Size in bytes (Stripped)",
          data: ALL_BENCHMARKS.map((a) => a.stripped_size),
          backgroundColor: colors,
        },
      ],
    },
    options: {
      scales: {
        y: {
          beginAtZero: false,
        },
      },
    },
  });
  const elementNames = [
    "mesa",
    "gnome-builder",
    "qemu",
    "GNOME-Builder-Plugins",
    "gtk",
  ];
  for (const element of elementNames) {
    ctx = document.getElementById(element.replaceAll("-", "_"));
    new Chart(ctx, {
      type: "bar",
      data: {
        labels: tags,
        datasets: [
          {
            label: "Time required for parsing (In ms)",
            data: ALL_BENCHMARKS.map((a) => findProject(a, element).parsing),
            backgroundColor: colors,
          },
        ],
      },
    });
    ctx = document.getElementById(`${element}_allocs`.replaceAll("-", "_"));
    new Chart(ctx, {
      type: "bar",
      data: {
        labels: tags,
        datasets: [
          {
            label: "Memory allocations",
            data: ALL_BENCHMARKS.map(
              (a) => findProject(a, element).memory_allocations,
            ),
            backgroundColor: colors,
          },
        ],
      },
    });
    ctx = document.getElementById(`${element}_tmp_allocs`.replaceAll("-", "_"));
    new Chart(ctx, {
      type: "bar",
      data: {
        labels: tags,
        datasets: [
          {
            label: "Temporary memory allocations",
            data: ALL_BENCHMARKS.map(
              (a) => findProject(a, element).temporary_memory_allocations,
            ),
            backgroundColor: colors,
          },
        ],
      },
      options: {
        scales: {
          y: {
            beginAtZero: false,
          },
        },
      },
    });
    ctx = document.getElementById(`${element}_rss`.replaceAll("-", "_"));
    new Chart(ctx, {
      type: "bar",
      data: {
        labels: tags,
        datasets: [
          {
            label: "Peak RSS (In MB)",
            data: ALL_BENCHMARKS.map((a) =>
              findProject(a, element).peak_rss.replace("M", ""),
            ),
            backgroundColor: colors,
          },
        ],
      },
    });
    ctx = document.getElementById(`${element}_heap`.replaceAll("-", "_"));
    new Chart(ctx, {
      type: "bar",
      data: {
        labels: tags,
        datasets: [
          {
            label: "Peak Heap (In MB)",
            data: ALL_BENCHMARKS.map((a) =>
              findProject(a, element).peak_heap.replace("M", ""),
            ),
            backgroundColor: colors,
          },
        ],
      },
    });
  }
}

function appendTr(tr, txt) {
  const td = document.createElement("td");
  td.appendChild(document.createTextNode(txt));
  tr.appendChild(td);
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
  appendTr(tr, "Measurement");
  appendTr(tr, oldData.commit);
  appendTr(tr, newData.commit);
  appendTr(tr, "Percentage");
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
  const elementNames = [
    "mesa",
    "gnome-builder",
    "qemu",
    "GNOME-Builder-Plugins",
    "gtk",
  ];
  for (const element of elementNames) {
    const p = findProject(oldData, element);
    const p1 = findProject(newData, element);
    tr = document.createElement("tr");
    tableBody.appendChild(tr);
    appendTr(tr, `Parsing ${element} 10 * 100 times`);
    appendTr(tr, p.parsing);
    appendTr(tr, p1.parsing);
    appendTr(tr, percentify(p.parsing, p1.parsing));
  }
  for (const element of elementNames) {
    const p = findProject(oldData, element);
    const p1 = findProject(newData, element);
    tr = document.createElement("tr");
    tableBody.appendChild(tr);
    appendTr(tr, `Memory allocations during parsing ${element}`);
    appendTr(tr, p.memory_allocations);
    appendTr(tr, p1.memory_allocations);
    appendTr(tr, percentify(p.memory_allocations, p1.memory_allocations));
  }
  for (const element of elementNames) {
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
  for (const element of elementNames) {
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
  for (const element of elementNames) {
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
}
