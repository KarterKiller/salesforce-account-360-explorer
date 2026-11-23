export const aggregateCounts = (graphData) => ({
    contacts: graphData?.contactCount || 0,
    opportunities: graphData?.opportunityCount || 0,
    cases: graphData?.caseCount || 0
});

export const filterNodes = (graphData, activeTypes, searchTerm) => {
    if (!graphData) return [];
    const search = (searchTerm || '').toLowerCase();
    return graphData.nodes.filter((node) => node.isCentral || (
        (!['Contact', 'Opportunity', 'Case'].includes(node.type) || activeTypes.has(node.type)) &&
        [node.label, node.subtitle, node.detailOne, node.detailTwo].filter(Boolean).join(' ').toLowerCase().includes(search)
    ));
};

export const isEmptyGraph = (graphData, activeTypes, searchTerm) => filterNodes(graphData, activeTypes, searchTerm).length <= 1;

export const connectedNodeIds = (links, selectedId) => {
    if (!selectedId) return new Set();
    const relatedIds = new Set([selectedId]);
    links.forEach((link) => {
        const source = typeof link.source === 'object' ? link.source.id : link.source;
        const target = typeof link.target === 'object' ? link.target.id : link.target;
        if (source === selectedId) relatedIds.add(target);
        if (target === selectedId) relatedIds.add(source);
    });
    return relatedIds;
};

export const labelLines = (label, maximumLineLength = 24) => {
    const words = (label || '').split(/\s+/).filter(Boolean);
    const lines = []; let line = '';
    words.forEach((word) => {
        if (line && `${line} ${word}`.length > maximumLineLength) { lines.push(line); line = word; }
        else line = line ? `${line} ${word}` : word;
    });
    if (line) lines.push(line);
    return lines.length > 2 ? [lines[0], lines.slice(1).join(' ')] : lines;
};

export const tooltipText = (node) => [node.type, node.label, node.subtitle, node.detailOne].filter(Boolean).join(' · ');
