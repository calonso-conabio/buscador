// Medidas para mostrar la gráfica
const width = window.innerWidth;
const height = window.innerHeight;
const maxRadius = (Math.min(width, height) / 2) - 5;
// b para mostrar la navegación de la gráfica > > >
var b = { w: 75, h: 30, s: 3, t: 10 };
// Formato de texto a mostrar (Para las cifras)
const formatNumber = d3.format(',d');
// La escala de colores a utilizar
const color = d3.scaleOrdinal(d3.schemeCategory20);
//const color = d3.scaleOrdinal(d3.quantize(d3.interpolateRainbow, json.children.length + 1));

const x = d3.scaleLinear()
    .range([0, 2 * Math.PI])
    .clamp(true);

const y = d3.scaleSqrt()
    .range([maxRadius * .1, maxRadius]);

const partition = d3.partition();

/* */
var arc = d3.arc()
    .startAngle(function (d) { return Math.max(0, Math.min(2 * Math.PI, x(d.x0))); })
    .endAngle(function (d) { return Math.max(0, Math.min(2 * Math.PI, x(d.x1))); })
    .innerRadius(function (d) { return Math.max(0, y(d.y0)); })
    .outerRadius(function (d) { return Math.max(0, y(d.y1)); });
/* */

/* * /
var arc = d3.arc()
    .startAngle(function (d) { return Math.max(0, Math.min(2 * Math.PI, x(d.x0))); })
    .endAngle(function (d) { return Math.max(0, Math.min(2 * Math.PI, x(d.x1))); })
    .innerRadius(d => d.y0 * maxRadius)
    .outerRadius(d => Math.max(d.y0 * maxRadius, d.y1 * maxRadius - 1));
/* */

// Para mostrar el nombre de cada estadística
const middleArcLine = d => {
    const halfPi = Math.PI / 2;
    const angles = [x(d.x0) - halfPi, x(d.x1) - halfPi];
    const r = Math.max(0, (y(d.y0) + y(d.y1)) / 2);
    const middleAngle = (angles[1] + angles[0]) / 2;
    const invertDirection = middleAngle > 0 && middleAngle < Math.PI;
    if (invertDirection) { angles.reverse(); }
    const path = d3.path();
    path.arc(0, 0, r, angles[0], angles[1], invertDirection);
    return path.toString();
};

// Para ajustar el nombre de cada estadística
const textFits = d => {
    const CHAR_SPACE = 2;
    const deltaAngle = x(d.x1) - x(d.x0);
    const r = Math.max(0, (y(d.y0) + y(d.y1)) / 2);
    const perimeter = r * deltaAngle;
    return d.data.name.length * CHAR_SPACE < perimeter;
};

// Seleccionar el div con id = chart para mostrar la gráfica
const svg = d3.select("#chart").append('svg')
    .attr("width", width)
    .attr("height", height)
    .append("svg:g")
    .attr("id", "container")
    .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
//.on('click', () => focusOn()); // Reset zoom on canvas click


// - - - - -  - - - - - - - - - -

text = " \n\
    Multimedia-Fotos-Tropicos,0 \n\
    Multimedia-Fotos-Maccaulay,1163 \n\
    Multimedia-Fotos-NaturaLista,1165 \n\
    Multimedia-Fotos-Banco de Imágenes de CONABIO,22730 \n\
    Multimedia-Videos-Maccaulay,1060 \n\
    Multimedia-Audio-Maccaulay,1553  \n\
    Fichas-CONABIO,600 \n\
    Fichas-EOL-español,9999 \n\
    Fichas-EOL-ingles,9999 \n\
    Fichas-Wikipedia-español,34168 \n\
    Fichas-Wikipedia-ingles,53478 \n\
    Nombres comunes-NaturaLista,11296 \n\
    Nombres comunes-CONABIO,24834 \n\
    Observaciones-NaturaLista (grado de investigación),2427 \n\
    Observaciones-NaturaLista (grado casual),6235 \n\
    SNIB-Ejemplares en el SNIB,60396 \n\
    SNIB-Ejemplares en el SNIB (aVerAves),1102 \n\
    Mapas-Mapas de distribución,99 \n\
";

// Función para comenzár a dibujar la gráfica
function start() {
    // Parsear el CVS
    var csv = d3.csvParseRows(text);
    // Pasaro a JSON
    var json = buildHierarchy(csv);
    // LLamar a la función que general la gráfica
    createVisualization(json);
}

function createVisualization(root) {
    root = d3.hierarchy(root);
    root.sum(d => d.size);

    // Inicializar el div que mostrará la navegación en la gráfica
    initializeBreadcrumbTrail();

    const slice = svg.selectAll('g.slice').data(partition(root).descendants());

    slice.exit().remove();

    // Por cada componente a mostrar, pegarle la función: focusOn
    const newSlice = slice.enter()
        .append('g').attr('class', 'slice')
        .on('click', d => {
            d3.event.stopPropagation();
            focusOn(d);
        });

    // Pegar el titulo a cada componente de la estadistica (se mostrará cuando el puntero se encuentra sobre el componente)
    newSlice.append('title').text(d => `${d.ancestors().map(d => d.data.name).reverse().join("/")}\n${formatNumber(d.value)}`);

    // Muestra el componente que representará la estadística
    newSlice.append('path')
        .attr('class', 'main-arc')
        .style("fill", function (d) {
            var c;
            // Si tiene es la raíz ponerle el color de conabio:
            if (d.depth === 0) {
                return "rgb(117 20 15)";
            } else if (d.depth === 1) {
                c = color((d.children ? d : d.parent).data.name);
            } else if (d.depth > 1) {
                c = d3.color(d.parent.data.color).darker();
            }
            d.data.color = c;
            return c;
        })
        .attr("fill-opacity", function (d) {
            var op = 1;
            if (d.depth === 0) {
                op = 1;
            } else if (d.depth === 1) {
                op = 0.9;
            } else if (d.depth > 1) {
                op = 0.9;
            }
            return op;
        })
        .style("opacity", 1)
        .on("mouseover", mouseover) // pegarle a los componentes la función mouseover
        .attr('d', arc);

    // A cada componenete pegarle clases y la etiqueta que contiene el nombre de la estadistica:
    newSlice.append('path')
        .attr('class', 'hidden-arc')
        .attr('id', (_, i) => `hiddenArc${i}`)
        .attr('d', middleArcLine);

    // Cuándo el puntrero no se encuentra dentro de la gráfica
    d3.select("#container").on("mouseleave", mouseleave);

    // Para el texto
    var text = newSlice.append("text")
        .attr('display', d => textFits(d) ? null : 'none')
        .style("fill", function (d) {
            if (d.depth === 0) {
                return "#CCC";
            } else {
                return "#FFF";
            }
        })
        .attr("class", "svglabel");

    // Agregar estilos al texto
    text.append('textPath')
        .attr('startOffset', '50%')
        .attr('xlink:href', (_, i) => `#hiddenArc${i}`)
        .text(d => d.data.name)
        .style('fill', 'none')
        .style('stroke', '#fff')
        .style('stroke-width', 0)
        .style('stroke-linejoin', 'round');

    text.append('textPath')
        .attr('startOffset', '50%')
        .attr('xlink:href', (_, i) => `#hiddenArc${i}`)
        .text(d => d.data.name);
};





// Generate a string that describes the points of a breadcrumb polygon.
function breadcrumbPoints(d, i) {
    var points = [];
    points.push("0,0");
    points.push((b.w ) + ",0");
    points.push((b.w ) + (b.t ) + "," + (b.h / 2));
    points.push((b.w ) + "," + b.h);
    points.push("0," + b.h);
    if (i > 0) { // Leftmost breadcrumb; don't include 6th vertex.
        points.push(b.t + "," + (b.h / 2));
    }
    return points.join(" ");
}

// Update the breadcrumb trail to show the current sequence and percentage.
function updateBreadcrumbs(nodeArray) {

    // Data join; key function combines name and depth (= position in sequence).
    var trail = d3.select("#trail")
        .selectAll("g")
        .data(nodeArray, function (d) { return d.data.name + d.depth; });

    // Remove exiting nodes.
    trail.exit().remove();

    // Add breadcrumb and label for entering nodes.
    var entering = trail.enter().append("svg:g");

    // En la navegación, utilizar el mismo color que los segmentos
    entering.append("svg:polygon")
        .attr("points", breadcrumbPoints)
        .style("fill", function (d) {
            var c;
            // Si tiene es la raíz:
            if (d.depth === 0) {
                return "rgb(117 20 15)";
            } else if (d.depth === 1) {
                c = color((d.children ? d : d.parent).data.name);
            } else if (d.depth > 1) {
                c = d3.color(d.parent.data.color).darker();
            }
            d.data.color = c;
            return c;
        });

    entering.append("svg:text")
        .attr("x", ((b.w) + b.t) / 2 - 25)
        .attr("y", b.h / 2 )
        .attr("dy", "0.35em")
        .attr("text-anchor", "start")
        .style("fill", 'white')
        .text(function (d) {
            d3.select("#estadistica").text(d.data.name);
            return d.data.name;
        });

    // Merge enter and update selections; set position for all nodes.
    entering.merge(trail).attr("transform", function (d, i) {
        return "translate(" + i * (b.w + b.s) + ", 0)";
    });

    // Now move and update the percentage at the end.
    d3.select("#trail").select("#endlabel")
        .attr("x", (nodeArray.length + 0.5) * (b.w + b.s))
        .attr("y", b.h / 2)
        .attr("dy", "0.35em")
        .attr("text-anchor", "middle");

    // Make the breadcrumb trail visible, if it's hidden.
    d3.select("#trail")
        .style("visibility", "");
}


// - - - - - - - - - - - - - - FUNCIONES

// Acercamiento a una parte específica de la tabla
function focusOn(d = { x0: 0, x1: 1, y0: 0, y1: 1 }) {
    // Reset to top-level if no data point specified
    const transition = svg.transition()
        .duration(1000)
        .tween('scale', () => {
            const xd = d3.interpolate(x.domain(), [d.x0, d.x1]),
                yd = d3.interpolate(y.domain(), [d.y0, 1]);
            return t => { x.domain(xd(t)); y.domain(yd(t)); };
        });

    transition.selectAll('path.main-arc')
        .attrTween('d', d => () => arc(d));

    transition.selectAll('path.hidden-arc')
        .attrTween('d', d => () => middleArcLine(d));

    transition.selectAll('text')
        .attrTween('display', d => () => textFits(d) ? null : 'none');
    transition.selectAll("text")
        .delay(400)
        .attrTween("opacity", function (n) {
            return function () {
                if (d === n || n.ancestors().includes(d)) {
                    return 1;
                } else {
                    return 0;
                }
            };
        });

    moveStackToFront(d);

    function moveStackToFront(elD) {
        svg.selectAll('.slice').filter(d => d === elD)
            .each(function (d) {
                this.parentNode.appendChild(this);
                if (d.parent) { moveStackToFront(d.parent); }
            })
    }
}


// - - - - - - - - - - - - - - HELPERS

// Crear a partir de un CSV, el arbol JSON
function buildHierarchy(csv) {
    var root = { "name": "Estadísticas CONABIO", "children": [] };
    for (var i = 0; i < csv.length; i++) {
        var sequence = csv[i][0];
        var size = +csv[i][1];
        if (isNaN(size)) { // e.g. if this is a header row
            continue;
        }
        var parts = sequence.split("-");
        var currentNode = root;
        for (var j = 0; j < parts.length; j++) {
            var children = currentNode["children"];
            var nodeName = parts[j];
            var childNode;
            if (j + 1 < parts.length) {
                // Not yet at the end of the sequence; move down the tree.
                var foundChild = false;
                for (var k = 0; k < children.length; k++) {
                    if (children[k]["name"] == nodeName) {
                        childNode = children[k];
                        foundChild = true;
                        break;
                    }
                }
                // If we don't already have a child node for this branch, create it.
                if (!foundChild) {
                    childNode = { "name": nodeName, "children": [] };
                    children.push(childNode);
                }
                currentNode = childNode;
            } else {
                // Reached the end of the sequence; create a leaf node.
                childNode = { "name": nodeName, "size": size };
                children.push(childNode);
            }
        }
    }
    return root;
};

// Función para inicializar la navegación de la gráfica
function initializeBreadcrumbTrail() {
    // Add the svg area.
    var trail = d3.select("#sequence").append("svg:svg")
        .attr("width", width)
        .attr("height", 30)
        .attr("id", "trail");
    // Add the label at the end, for the percentage.
    trail.append("svg:text")
        .attr("id", "endlabel")
        .style("fill", "#000");
}

// Cuando el puntero se encuentra en un segmento de la gráfica
function mouseover(d) {

    // Mostrar el valor que representa cada segmento por el que el puntero se encuentre dentro de la gráfica
    d3.select("#percentage").text(d.value);
    d3.select("#explanation").style("visibility", "");

    // Obtener la secuencia para llegar al segmento seleccionado y mostrarlo en la navegación
    var sequenceArray = d.ancestors().reverse();
    sequenceArray.shift(); // remove root node from the array
    updateBreadcrumbs(sequenceArray);

    // Opacar todos los segmentos
    d3.selectAll("path")
        .style("opacity", function (d) {
            if (d.depth > 0) {
                return 0.6;
            }
        });

    // Mostrar sin opacidad sólo el segmento por el que el puntero se encuentre
    svg.selectAll("path")
        .filter(function (node) {
            return (sequenceArray.indexOf(node) >= 0);
        })
        .style("opacity", 1);
}

// Cuándo el puntero esta fuera del área de la estadistica:
function mouseleave(d) {
    // Ocultar la barra de navegacioón
    d3.select("#trail").style("visibility", "hidden");

    // Desactivar el mouseover
    d3.selectAll("path").on("mouseover", null);

    // Regresar a la normalidad todos los segmentos existentes
    d3.selectAll("path")
        .transition()
        .duration(400)
        .style("opacity", 1)
        .on("end", function () {
            d3.select(this).on("mouseover", mouseover);
        });
    // Ocultar el div que describe a los sem¡gmentos seleccionados
    d3.select("#explanation")
        .style("visibility", "hidden");
}
