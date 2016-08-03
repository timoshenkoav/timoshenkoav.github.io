---
layout: post
title:  "Display RecyclerView sections like Android Lollipop contacts application"
date:   2015-12-11 16:30:00
tags: android recyclerview
related_posts: 2 3
---

One of my projects require to display sticky headers like Android Contacts app do on Android Lollipop.

After some time of investigation i've found simple way to archive this looks and feel. Now its quite naive and requires a lot of improvement, but its quite usable.

I'll start implementation from describing how to get sections index for loaded list of contacts.

Here is simple model class to store contact information fetched from ContentProvider.

{%highlight java%}
public class Contact {
    private String mName;

    public Contact(String pName) {
        mName = pName;
    }

    // ... Getters and Setters
}
{%endhighlight%}

Its quite simple, as everything we need to showcast is contact name.

To build section index we need sort our list of contacts by name alphabetically. I'll skip this part, as its quite straight forward, if you want go deep, checkout github link down this post.

When we have our sorted contacts list, we can fill section index

{%highlight java%}
mMapIndex = new LinkedHashMap<String, Integer>();
for (int x = 0; x < mContacts.size(); x++) {
    String contact = mContacts.get(x).getName();
    if (contact.length() > 1) {
        String ch = contact.substring(0, 1);
        ch = ch.toUpperCase();
        if (!mMapIndex.containsKey(ch)) {
            mMapIndex.put(ch, x);
        }
    }
}
Set<String> sectionLetters = mMapIndex.keySet();
// create a list from the set to sort
mSectionList = new ArrayList<String>(sectionLetters);
Collections.sort(mSectionList);

mSections = new String[mSectionList.size()];
mSectionList.toArray(mSections);

{%endhighlight%}

In result we got some variables that can be used for section headers

* mMapIndex - map of contact name uppercased first character and index of first contact in list
* mSectionList - list of all sections sorter alphabetically

Now, when we have sections, we can start displaying contacts in Views. Item layout has TextView to display contact name, and section title to display section when required.

{%highlight xml%}
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
                xmlns:tools="http://schemas.android.com/tools"
                android:layout_width="match_parent"
                android:layout_height="match_parent"
                android:orientation="horizontal"
                android:paddingBottom="20dp"
                android:paddingRight="10dp">

    <TextView
        android:id="@+id/section_title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textAppearance="?android:textAppearanceMedium"
        android:textColor="#000"
        tools:text="A"/>

    <TextView
        android:id="@+id/name"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginLeft="60dp"
        android:textAppearance="?android:textAppearanceMedium"
        android:textColor="#000"
        tools:text="Contact Name"/>
</RelativeLayout>
{%endhighlight%}


To detect if we need to display section, we have **mMapIndex** HashMap, if list position we want to bind to viewholder equals to section position we display section title **TextView**, or hide it otherwise.

In simplest case ViewHolder gets such code:

{%highlight java%}
private class ContactViewHolder extends RecyclerView.ViewHolder {
    private final TextView mName;
    private final TextView mSectionName;

    public ContactViewHolder(View itemView) {
        super(itemView);
        mName = (TextView) itemView.findViewById(R.id.name);
        mSectionName = (TextView) itemView.findViewById(R.id.section_title);

    }

    public void bind(Contact pItem, String pSection, boolean bShowSection) {
        mName.setText(pItem.getName());
        mSectionName.setText(pSection);
        mSectionName.setVisibility(bShowSection ? View.VISIBLE : View.GONE);
    }
}
{%endhighlight%}

Binding ViewHolder is also straightforward:

{%highlight java%}
@Override
public void onBindViewHolder(ContactViewHolder holder, int position) {
    Contact lContact = getItem(position);
    String section = getSection(lContact);
    holder.bind(lContact, section, mMapIndex.get(section) == position);
}
private String getSection(Contact pContact) {
    return pContact.getName().substring(0, 1).toUpperCase();
}
{%endhighlight%}

Now we can load and display contact list with section titles displayed on the first section item. Now we need to handle **RecyclerView** scrolling to get sticky headers behavior.

I will not put all code for this logic here, you can find it in GitHub project listed in the end of this article.
The main logic is to have **TextView** with the same style as section title item in item list and show/hide appropriate TextView in the item and animate TextView in the Activity. 
This solution is not fully completed, and may have some issues under some unexpected circumstances, but as its opensourced you can easily create issue or submit your pull request.

You can find complete source code on {% include ga_link.html title="GitHub" url="https://github.com/timoshenkoav/RecyclerViewSections" %}
Enjoy!

