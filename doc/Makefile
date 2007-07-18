# Generate texinfo documents
# 
# make pdf
#   Generate a pdf
#
# make html
#   Generate a single webpage
#
# make html-split
#   Generate a mutlple page webpage
#

pdf : matbots.pdf
html : matbots.html

matbots.pdf : matbots.texi
	texi2pdf matbots.texi

matbots.html : matbots.texi
	texi2html matbots.texi

html-split : matbots.texi
	texi2html --split chapter matbots.texi
