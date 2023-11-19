namespace Controls
{
    class Pagination {

        int page = 0;
        int total = 0;
        int pageCount = 0;

        int m_limit = 3;

        bool isPageRequested = false;
        int requestedPageIndex = 0;

        void Render() {
            isPageRequested = false;
            requestedPageIndex = 0;

            if (page > 0) {
                PageButton(page - 1, "Prev Page");
            }

            UI::BeginGroup();
            for (uint i = Math::Max(0, page - m_limit); i < page; i++) {
                PageButton(i);
            }

            UI::BeginDisabled();
            PageButton(page);

            UI::EndDisabled();
            
            for (uint i = page + 1; i < Math::Min(pageCount, page + m_limit + 1); i++) {
                PageButton(i);
            }

            if (pageCount > page + 1) {
                PageButton(page + 1, "Next Page");
            }
            UI::EndGroup();
        }

        void PageButton(int pageIndex, string label = "") {
            if (label == "") {
                label = "" + (pageIndex + 1);
            }
            if (UI::Button(label)) {
                isPageRequested = true;
                requestedPageIndex = pageIndex;
            }
            UI::SameLine();
        }
    }
}