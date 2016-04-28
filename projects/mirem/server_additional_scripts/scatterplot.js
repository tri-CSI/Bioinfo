function PlotScatter(plotArea, data)	{
	
	var tip = d3.tip()
  .attr('class', 'd3-tip')
  .attr('id', 'tipcoor')
  .offset([-10, 0])
  .html(function(d) {
    return "<strong>miRNA:</strong> <span style='color:yellow'>" + d[2] + "</span></br>\
	<strong>EM-value:</strong> <span style='color:red'>" + d[1].toFixed(3) + "</span></br>\
	<strong>-log(HG-value):</strong> <span style='color:red'>" + d[0].toFixed(3) + "</span>";
  });
  
  	var popup = d3.tip()
		.attr('class', 'd3-tip')
		.attr('id', 'tipglist')
		.offset([20, 0])
		.style('fill', "yellow")
		.html(function(d) {
			glist = d[3].split(",");
			glist.pop();
			size = glist.length;
			list = "";
			for (var i = 0; i < size; i++) {
				list += glist[i]+", ";
				}
			return "Gene list (" + size + " genes): \
			<span style='color:cyan'>" + list + "</span>";
		})
		.direction('e');
  
	var data = data;
	var copy = data.slice(0); 
	
    var margin = {top: 60, right: 60, bottom: 60, left: 60}
      , width = 910 - margin.left - margin.right
      , height = 500 - margin.top - margin.bottom;
	  
	var xmax = (function maxSense(d) {
		if (d.length == 1) return d[0][0] == Infinity ? 0 : d[0][0];
		else {
			myd1 = d.shift()
			myd1 = myd1[0] == Infinity ? 0 : myd1[0];
			return Math.max(myd1, maxSense(d));
		}
	})(copy);
    
    var x = d3.scale.linear()
              .domain([0, xmax*1.3])
              .range([ 0, width ]);
    
    var y = d3.scale.linear()
    	      .domain([0, d3.max(data, function(d) { return d[1]*1.3; })])
    	      .range([ height, 0 ]);
 
    var chart = d3.select(plotArea)
		.append('svg:svg')
		.attr('width', width + margin.right + margin.left)
		.attr('height', height + margin.top + margin.bottom)
		.attr('class', 'chart')

    var main = chart.append('g')
		.attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
		.attr('width', width)
		.attr('height', height)
		.attr('class', 'main')   
        
    // draw the x axis
    var xAxis = d3.svg.axis()
		.scale(x)
		.orient('bottom');

	main.append("text")
        .attr("x", (width / 2))             
        .attr("y", 0 - (margin.top / 2))
        .attr("text-anchor", "middle")  
        .style("font-size", "20px") 
        .style("font-weight", "bold")  
        .text("Graph of EM vs -log(HG-value)");
	
    main.append('g')
		.attr('transform', 'translate(0,' + height + ')')
		.attr('class', 'main axis date')
		.call(xAxis)
	.append("text")
		.attr("transform", "translate(" + width/2 + "," + (margin.bottom/3*2) + ")")
        .style("text-anchor", "middle")
		.style("font-weight", "bold")
		.text("-log(adjusted HG p-value)");
    // draw the y axis
    var yAxis = d3.svg.axis()
	.scale(y)
	.orient('left');

    main.append('g')
		.attr('transform', 'translate(0,0)')
		.attr('class', 'main axis date')
		.call(yAxis)
	.append("text")
        .attr("transform", "rotate(-90)")
        .attr("y", 0 - margin.left)
        .attr("x",0 - (height / 2))
        .attr("dy", "1em")
        .style("text-anchor", "middle")
		.style("font-weight", "bold").call(tip).call(popup)
		.text("EM probability");
	
	main.selectAll('.axis line, .axis path')
		.style({'stroke': 'Black', 'fill': 'none'});
	
	// data points

    var g = main.append("svg:g"); 
	//dummy data for saving
    showing = false;
    g.selectAll("scatter-dots")
		.data(data)
		.enter().append("svg:circle")
			.attr("cx", function (d,i) { return x(d[0] == Infinity ? xmax*1.3 : d[0]); } )
			.attr("cy", function (d) { return y(d[1]); } )
			.attr("id", function (d) { return d[2]; } )
			.attr("r", 8)
			.on('mouseover', tip.show)
			.on('mouseout', tip.hide)
			.on('click', function(d) { showing =! showing; showing ? popup.show(d): popup.hide();});
	d3.selectAll("#tipglist").on('dblclick', function() { showing = false; popup.hide();});
	
	var firstpt = data[0];
	
	var l1 = g.append("text")
		.attr("x", 10)
		.attr("y", 40)
		.text("Best miRNA prediction according to EM score: " + firstpt[2] + ", score: " + firstpt[1].toFixed(3));
	
	var smallHg = d3.max(data, function(d) { return d[0]; });
	var firstHg = Math.pow(10, - smallHg);
	var mirna = data.filter(function(v) { return v[0] == smallHg;})[0][2];

	var l2 = g.append("text")
		.attr("x", 10)
		.attr("y", 10)
		.text("Best miRNA prediction according to HG score: " + mirna + ", score: " + firstHg.toExponential(3));
		
	main.selectAll('circle')
		.style({'fill': '#253494'});
	
	
	d3.select("#savegraph").on("click", function(){
		
		// Save plot as PNG
		var html = d3.select("svg")
			.attr("version", 1.2)
			.attr("xmlns", "http://www.w3.org/2000/svg")
			.node().parentNode.innerHTML;
		//console.log(html);
		var imgsrc = 'data:image/svg+xml;base64,'+ btoa(html);
		var img = '<img style="width:910" src="'+imgsrc+'">'; 
		d3.select("#svgdataurl").html(img);
		var doctype = '<?xml version="1.0" standalone="no"?>' + '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">';

		// serialize our SVG XML to a string.
		var source = (new XMLSerializer()).serializeToString(d3.select('svg').node());

		// create a file blob of our SVG.
		var blob = new Blob([ doctype + source], { type: 'image/svg+xml;charset=utf-8' });

		var url = window.URL.createObjectURL(blob);
		// Put the svg into an image tag so that the Canvas element can read it in.
		var img = d3.select('body').append('img')
			.attr('width', 910)
			.attr('height', 500)
			.style("display", "none") 
			.node();
		
		img.onload = function(){
			// Now that the image has loaded, put the image into a canvas element.
			var canvas = d3.select('body').append('canvas').style("display", "none").node();
			canvas.width = 910;
			canvas.height = 500;
			var ctx = canvas.getContext('2d');
			ctx.drawImage(img, 0, 0);
			var canvasUrl = canvas.toDataURL("image/png");
			var img2 = d3.select('body').append('img')
			.attr('width', 910)
			.attr('height', 500)
			.style("display", "none") 
			.node();
			// this is now the base64 encoded version of our PNG! you could optionally 
			// redirect the user to download the PNG by sending them to the url with 
			// `window.location.href= canvasUrl`.
			img2.src = canvasUrl; 
			var a = document.createElement('a');
			a.download = "em-hg-plot.png";
			a.href = canvas.toDataURL('image/png');
			document.body.appendChild(a);
			a.click();

		}
		// start loading the image.
		img.src = url;
	});
}
