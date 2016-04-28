function PlotPhylo()	{
	d3.select("#savephylo").on("click", function(){
    	var doctype = '<?xml version="1.0" standalone="no"?>' + '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">';

		// serialize our SVG XML to a string.
		var source = (new XMLSerializer()).serializeToString(d3.select('#phylocanvas > svg').node())
                    .replace('width="850"','width="1000"')
                    .replace('height="800"','height="1000"')
                    .replace('style="','viewBox="-50 -50 1000 1000" style="overflow:visible;');

		// create a file blob of our SVG.
		var blob = new Blob([ doctype + source], { type: 'image/svg+xml;charset=utf-8' });
        saveAs(blob, "mirnaPhylo.svg");
        
        /*
		var url = window.URL.createObjectURL(blob);
		// Put the svg into an image tag so that the Canvas element can read it in.
		var img = d3.select('body').append('img')
			.attr('width', 1000)
			.attr('height', 1000)
			.style("display", "none") 
			.node();
		
		img.onload = function(){
			// Now that the image has loaded, put the image into a canvas element.
			var canvas = d3.select('body').append('canvas').style("display", "none").node();
			canvas.width = 1000;
			canvas.height = 1000;
			var ctx = canvas.getContext('2d');
			ctx.drawImage(img, 0, 0);
			var canvasUrl = canvas.toDataURL("image/png");
			var img2 = d3.select('body').append('img')
			.attr('width', 1000)
			.attr('height', 1000)
			.style("display", "none") 
			.node();
			// this is now the base64 encoded version of our PNG! you could optionally 
			// redirect the user to download the PNG by sending them to the url with 
			// `window.location.href= canvasUrl`.
			img2.src = canvasUrl; 
			var a = document.createElement('a');
			a.download = "phylo-tree.png";
			a.href = canvas.toDataURL('image/png');
			document.body.appendChild(a);
			a.click();

		}
		// start loading the image.
		img.src = url;*/
	});
}
