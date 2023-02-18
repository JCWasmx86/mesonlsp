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

function createOverviewCharts() {
  ctx = document.getElementById("sizeChart");
  const tags = ALL_BENCHMARKS.map((a) => a.commit);
  const colors = ["#1c71d8", "#c01c28", "#613583"];
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
    ctx = document.getElementById((element + "_allocs").replaceAll("-", "_"));
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
    ctx = document.getElementById(
      (element + "_tmp_allocs").replaceAll("-", "_"),
    );
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
    });
    ctx = document.getElementById((element + "_rss").replaceAll("-", "_"));
    new Chart(ctx, {
      type: "bar",
      data: {
        labels: tags,
        datasets: [
          {
            label: "Peak RSS",
            data: ALL_BENCHMARKS.map((a) =>
              findProject(a, element).peak_rss.replace("M", ""),
            ),
            backgroundColor: colors,
          },
        ],
      },
    });
    ctx = document.getElementById((element + "_heap").replaceAll("-", "_"));
    new Chart(ctx, {
      type: "bar",
      data: {
        labels: tags,
        datasets: [
          {
            label: "Peak Heap",
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
