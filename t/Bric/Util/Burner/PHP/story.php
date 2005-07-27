<?php
# Convenience variables.
$story   = $BRIC['story'];
$element = $BRIC['element'];
$burner  = $BRIC['burner'];
foreach ($element->get_elements('header', 'para', '_pull_quote_') as $e) {
    $kn = $e->get_key_name();
    if ($kn == 'para') {
        echo '<p>', $e->get_data(), "</p>\n";
    } else if ($kn == 'header') {
        # Test sdisplay_element() on a field.
        echo '<h3>', $burner->sdisplay_element($e), "</h3>\n";
    } else if ($kn == '_pull_quote_' && $e->get_object_order() > 1) {
        # Test sdisplay_element() on a container.
        echo $burner->sdisplay_element($e);
    } else {
        # Test display_element().
        $burner->display_element($e);
    }
}
$burner->display_pages('_page_');
?>
