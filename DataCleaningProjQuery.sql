Select SaleDate
From DataCleaningProj..NashvilleHousing


-- Standardize Date Format 

--What we want
Select SaleDate, Convert(date, SaleDate)
From DataCleaningProj..NashvilleHousing

--Method 1
Update NashvilleHousing
Set SaleDate = Convert(date, SaleDate)
From DataCleaningProj..NashvilleHousing
--This Method did not work for Unknown Reason

Select SaleDate
From DataCleaningProj..NashvilleHousing

--Method 2
Alter Table DataCleaningProj..NashvilleHousing
Add SaleDateConverted Date
Go 

Update DataCleaningProj..NashvilleHousing
Set SaleDateConverted = CONVERT(date, Saledate)

Select SaleDateConverted, SaleDate
From DataCleaningProj..NashvilleHousing
-- This Method Worked 

--Method 3 
-- Go to Tables and Right click -> modify the column to date data type 
--This Method Worked, but is a permanent change to the Table 




--Populate Property Adress Data 
Select *
From DataCleaningProj..NashvilleHousing
where PropertyAddress is Null


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
From DataCleaningProj..NashvilleHousing AS a 
JOIN DataCleaningProj..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ]
Where a.PropertyAddress is Null
--All these have a corresponding Address we can use populate 


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
ISNULL(a.PropertyAddress,b.PropertyAddress)
From DataCleaningProj..NashvilleHousing AS a 
JOIN DataCleaningProj..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ]
Where a.PropertyAddress is Null
-- Our Output shows the correct Property Address

--Update the Table

Update a -- When Updating with a JOIN, we Must address the table by its alias 
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From DataCleaningProj..NashvilleHousing AS a 
JOIN DataCleaningProj..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ]
Where a.PropertyAddress is Null

-- We see no Nulls come up and confirm we did it correctly 
Select *
From DataCleaningProj..NashvilleHousing
where PropertyAddress is Null


--Breaking Out Address into Individual Columns (Address, City, State)

Select PropertyAddress
From DataCleaningProj..NashvilleHousing

--Get Address
select CHARINDEX(',', PropertyAddress) CharPosition, -- the commma is in this position 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address
From DataCleaningProj..NashvilleHousing
-- -1 to omit the comma 

--Get City 
Select SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress), Len(PropertyAddress)),
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, Len(PropertyAddress)) AS City
From DataCleaningProj..NashvilleHousing
--Start at the comma position and end at the end charachter (which is the Len of the string) 
-- +2 to omit the comma and the space after it 

--Create the New Columns
Alter Table DataCleaningProj..NashvilleHousing
Add PropertySplitAddress nvarchar(255), 
	PropertySplitCity nvarchar(255)

--Update the table: Insert the new data  
Update DataCleaningProj..NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) ,
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, Len(PropertyAddress))
From DataCleaningProj..NashvilleHousing


Select PropertySplitAddress, PropertySplitCity
From DataCleaningProj..NashvilleHousing


-- do it again with owner Address
--Using ParseName
Select OwnerAddress
From DataCleaningProj..NashvilleHousing

--Parsename only works if the delimiter is a period, 
--so we use Replace() to turn commas to periods 
--Note we are replace(', ') with a period to replace leading spaces 
--Parsename parses from back to front, so the 1s parse will be the State of the Address
Select PARSENAME(Replace(OwnerAddress, ', ', '.'), 3),
	PARSENAME(Replace(OwnerAddress, ', ', '.'), 2),
	PARSENAME(Replace(OwnerAddress, ', ', '.'), 1)
From DataCleaningProj..NashvilleHousing

--Lets add and update our new Columns 

Alter Table DataCleaningProj..NashvilleHousing
Add OwnerSplitAddress nvarchar(255), 
	OwnerSplitCity nvarchar(255),
	OwnerSplitState nvarchar(225)

Update DataCleaningProj..NashvilleHousing
Set 
OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ', ', '.'), 3),
OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ', ', '.'), 2),
OwnerSplitState = PARSENAME(Replace(OwnerAddress, ', ', '.'), 1)
From DataCleaningProj..NashvilleHousing

Select OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
From DataCleaningProj..NashvilleHousing



--Change Y and N to Yes and No in the SoldAsVacant Field
Select Distinct SoldAsVacant, --we see 4 distinct values 
Case When SoldAsVacant = 'Y' Then 'Yes'
	 When SoldAsVacant = 'N' Then 'No'
	 Else SoldAsVacant
	 End 
From DataCleaningProj..NashvilleHousing 

--Lets Update our data 
Update DataCleaningProj..NashvilleHousing
Set SoldAsVacant = 
Case When SoldAsVacant = 'Y' Then 'Yes'
	 When SoldAsVacant = 'N' Then 'No'
	 Else SoldAsVacant
	 End 
From DataCleaningProj..NashvilleHousing 

--Check 
Select Distinct SoldAsVacant
From DataCleaningProj..NashvilleHousing

--Remove Duplicates 
--Write a CTE for deleting duplicates
-- If we  have a unique ID, 
--	We need to partition by many fields to make sure their are multiple rows with the same information 
WITH CTE_RowNum AS(
Select *, 
	ROW_NUMBER() over (
	Partition By ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order By UniqueID
				 ) AS row_num
From DataCleaningProj..NashvilleHousing
)

Select *
From CTE_RowNum 
Where row_num > 1

-- Borrow the CTE 
WITH CTE_RowNum AS(
Select *, 
	ROW_NUMBER() over (
	Partition By ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order By UniqueID
				 ) AS row_num
From DataCleaningProj..NashvilleHousing
)



--Exclude the duplicates
Select *
From CTE_RowNum 
Where row_num = 1

--PERMANENT DELETION OF THE THE DUPLICATES
WITH CTE_RowNum AS(
Select *, 
	ROW_NUMBER() over (
	Partition By ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order By UniqueID
				 ) AS row_num
From DataCleaningProj..NashvilleHousing
)

DELETE
From CTE_RowNum 
Where row_num > 1

--Delete Unused Columns 
Select *
From DataCleaningProj..NashvilleHousing

Alter Table DataCleaningProj..NashvilleHousing 
Drop Column OwnerAddress, TaxDistrict, PropertyAddress, AddressSplit, CitySplit, SaleDate

Select *
From DataCleaningProj..NashvilleHousing





