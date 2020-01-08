var width = 500,
    height = 500,
    radius = Math.min(width, height) / 2,
    innerRadius = 0.3 * radius;

var pie = d3.layout.pie()
    .sort(null)
    .value(function(d) { return d.width; });

var tip = d3.tip()
    .attr('class', 'd3-tip')
    .offset([0, 0])
    .html(function(d) {
        return I18n.t('simple_form.options.metamares_proyecto.region.nombre_region.' + d.data.label) + ": <span style='color:orangered'>" + d.data.totales + "</span>";
    });

var arc = d3.svg.arc()
    .innerRadius(innerRadius)
    .outerRadius(function (d) {
        return (radius - innerRadius) * (d.data.score / 100.0) + innerRadius;
    });

var outlineArc = d3.svg.arc()
    .innerRadius(innerRadius)
    .outerRadius(radius);

var svg = d3.select("#grafica-pie").append("svg")
    .attr("width", width)
    .attr("height", height)
    .append("g")
    .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

svg.call(tip);


//d3.csv('/grafica_pie.csv', function(error, data) {
d3.json("/metamares/grafica2", function(data) {
    var totales = 0;
    data.forEach(function(d) {
        d.id     =  d.id;
        d.order  = +d.order;
        d.color = "#" + Math.random().toString(16).slice(2, 8).toUpperCase();
        d.weight = +d.weight;
        d.score  = +d.score;
        d.width  = +d.weight;
        d.label  =  d.label;
        totales  = totales+d.totales;
    });

    var path = svg.selectAll(".solidArc")
        .data(pie(data))
        .enter().append("path")
        .attr("fill", function(d) { return d.data.color; })
        .attr("class", "solidArc")
        .attr("stroke", "gray")
        .attr("d", arc)
        .on('mouseover', tip.show)
        .on('mouseout', tip.hide);

    var outerPath = svg.selectAll(".outlineArc")
        .data(pie(data))
        .enter().append("path")
        .attr("fill", "none")
        .attr("stroke", "gray")
        .attr("class", "outlineArc")
        .attr("d", outlineArc);

    svg.append("svg:text")
        .attr("class", "aster-score")
        .attr("dy", ".35em")
        .attr("text-anchor", "middle") // text-align: right
        .style("font-size", "2.5em")
        .text(totales);

});