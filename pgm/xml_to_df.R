# Fonction externe pour convertir un xml en df  https://gist.github.com/GuillaumePressiat/27465b3f34a617527baf659c1fcf96f0
xml_to_df <- function(doc, ns = xml_ns(doc)) {
  library(xml2)
  library(purrr)
  split_by <- function(.x, .f, ...) {
    vals <- map(.x, .f, ...)
    split(.x, simplify_all(transpose(vals)))
  }
  node_to_df <- function(node) {
    # Filter the attributes for ones that aren't namespaces
    # x <- list(.index = 0, .name = xml_name(node, ns))
    x <- list(.name = xml_name(node, ns))
    # Attributes as column headers, and their values in the first row
    attrs <- xml_attrs(node)
    if (length(attrs) > 0) {attrs <- attrs[!grepl("xmlns", names(attrs))]}
    if (length(attrs) > 0) {x <- c(x, attrs)}
    # Build data frame manually, to avoid as.data.frame's good intentions
    children <- xml_children(node)
    if (length(children) >= 1) {
      x <- 
        children %>%
        # Recurse here
        map(node_to_df) %>%
        split_by(".name") %>%
        map(bind_rows) %>%
        map(list) %>%
        {c(x, .)}
      attr(x, "row.names") <- 1L
      class(x) <- c("tbl_df", "data.frame")
    } else {
      x$.value <- xml_text(node)
    }
    x
  }
  node_to_df(doc)
}
